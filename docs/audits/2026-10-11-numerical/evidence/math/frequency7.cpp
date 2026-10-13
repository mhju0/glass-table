#include <array>
#include <iostream>
// Independent direct seven-card classification. No five-card subsets or engine code.
int straightHigh(unsigned mask) {
    for (int high=14; high>=6; --high) {
        bool full=true;
        for(int rank=high-4;rank<=high;++rank) if(!(mask & (1u<<rank))) {full=false;break;}
        if(full)return high;
    }
    if((mask & ((1u<<14)|(1u<<5)|(1u<<4)|(1u<<3)|(1u<<2))) == ((1u<<14)|(1u<<5)|(1u<<4)|(1u<<3)|(1u<<2)))return 5;
    return 0;
}
int category(const std::array<int,7>& cards, bool& royal) {
    int ranks[15]={},suits[4]={}; unsigned mask=0, suitMask[4]={};
    for(int card:cards) {int r=card/4+2,s=card%4;++ranks[r];++suits[s];mask|=1u<<r;suitMask[s]|=1u<<r;}
    for(int s=0;s<4;++s) if(suits[s]>=5 && straightHigh(suitMask[s])) {royal=straightHigh(suitMask[s])==14;return 8;}
    int pairs=0,trips=0;
    for(int r=2;r<=14;++r){if(ranks[r]==4)return 7;if(ranks[r]==3)++trips;if(ranks[r]==2)++pairs;}
    if(trips>=1 && (pairs>=1 || trips>=2))return 6;
    for(int s=0;s<4;++s)if(suits[s]>=5)return 5;
    if(straightHigh(mask))return 4;
    if(trips)return 3;
    if(pairs>=2)return 2;
    if(pairs)return 1;
    return 0;
}
int main(){long long counts[9]={},royals=0;std::array<int,7> hand;
for(int a=0;a<46;++a){hand[0]=a;for(int b=a+1;b<47;++b){hand[1]=b;for(int c=b+1;c<48;++c){hand[2]=c;for(int d=c+1;d<49;++d){hand[3]=d;for(int e=d+1;e<50;++e){hand[4]=e;for(int f=e+1;f<51;++f){hand[5]=f;for(int g=f+1;g<52;++g){hand[6]=g;bool royal=false;++counts[category(hand,royal)];royals+=royal;}}}}}}}
std::cout<<"{\"gate\":\"independentFull7\",\"counts\":[";long long total=0;for(int i=0;i<9;++i){if(i)std::cout<<',';std::cout<<counts[i];total+=counts[i];}std::cout<<"],\"royals\":"<<royals<<",\"total\":"<<total<<"}\n";
}
