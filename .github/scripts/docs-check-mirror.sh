#!/bin/sh
# Used by .github/workflows/ci-docs.yml. Usage: docs-check-mirror.sh <job name>
# Exit 0 when the PR changes only paths ci.yml ignores. Otherwise wait for ci.yml's
# check run of the same name on this commit and exit with its result.
set -eu
job=$1
repo=$GITHUB_REPOSITORY
pr=$(jq -r .pull_request.number "$GITHUB_EVENT_PATH")
sha=$(jq -r .pull_request.head.sha "$GITHUB_EVENT_PATH")

# Keep in sync with paths-ignore in ci.yml.
other=$(gh api --paginate "repos/$repo/pulls/$pr/files" --jq '.[].filename' |
  grep -Ev '^docs/|\.md$|^\.github/ISSUE_TEMPLATE/' || true)
if [ -z "$other" ]; then
  echo "Docs-only change; ci.yml does not run. $job passes."
  exit 0
fi

echo "Non-doc files changed; waiting for ci.yml's $job on $sha:"
echo "$other" | head -20
while :; do
  conclusion=$(gh api "repos/$repo/commits/$sha/check-runs?check_name=$job&per_page=100" \
    --jq "[.check_runs[] | select(.details_url | contains(\"/runs/$GITHUB_RUN_ID/\") | not)]
          | sort_by(.started_at) | last | if . == null then \"missing\"
            elif .status != \"completed\" then \"pending\" else .conclusion end")
  case "$conclusion" in
    success) echo "ci.yml $job passed."; exit 0 ;;
    missing|pending) sleep 30 ;;
    *) echo "ci.yml $job ended: $conclusion"; exit 1 ;;
  esac
done
