#include <stdio.h>
#include "treeverse.h"

int str2int(char *str) {
  int res = 0 ;
  while(*str) {
    res = (res * 10) + (*str) - '0' ;
    str++ ;
  }
  return(res) ;
}

int main(int argc, char *argv[]) {
  int action,step ;
  int nstp = 10 ;
  int nsnp = 3 ;
  if (argc>1) nstp=str2int(argv[1]) ;
  if (argc>2) nsnp=str2int(argv[2]) ;
  printf("REVERSING %i STEPS WITH %i SNAPSHOTS:\n",nstp,nsnp) ;
  trv_init(nstp, nsnp, 1) ;
  while (trv_next_action(&action, &step)) {
    switch (action) {
    case PUSHSNAP :
      printf("[%i] PUSH SNAPSHOT    %i\n",action,step) ;
      break ;
    case LOOKSNAP :
      printf("[%i] LOOK SNAPSHOT    %i\n",action,step) ;
      break ;
    case POPSNAP :
      printf("[%i] POP SNAPSHOT     %i\n",action,step) ;
      break ;
    case ADVANCE :
      printf("[%i] ADVANCE ONE STEP %i\n",action,step) ;
      break ;
    case FIRSTTURN :
      printf("[%i] FIRST TURN       %i\n",action,step) ;
      break ;
    case TURN :
      printf("[%i] TURN             %i\n",action,step) ;
      break ;
    default :
      printf("[%i] ??               %i\n",action,step) ;
      break ;
    }

    if (step==8 && action==4) {
      printf("  =============> step 8: TRV_RESIZE() !!!\n") ;
      trv_resize() ;
    }
  }
}
