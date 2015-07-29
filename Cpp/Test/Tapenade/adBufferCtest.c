#include <stdio.h>
#include "adBuffer.h"
#include "adStack.h"

int main(int argc, char *argv[]) {
  double x, Y[10], px, PY[10] ;
  int a, B[20], pa, PB[20] ;
  int pc1, pc2, pc3, pc4 ;
  int i ;

  x = -1.0 ;
  for (i=0 ; i<10 ; ++i)
    Y[i] = i*1.1 ;
  a = -1 ;
  for (i=0 ; i<20 ; ++i)
    B[i] = i ;

  pushreal8(x) ;
  pushreal8array(Y,10) ;
  pushcontrol1b(1) ;
  pushcontrol3b(4) ;
  pushcontrol1b(0) ;
  pushcontrol5b(14) ;

  showallstacks() ;

  pushinteger4(a) ;
  pushinteger4array(B,20) ;

  showallstacks() ;

  popinteger4array(PB,20) ;

  showallstacks() ;

  lookinteger4(&pa) ;
  printf("l -1:%i\n",pa) ;
  lookcontrol5b(&pc1) ;
  printf("l 14?:%i\n",pc1) ;
  lookcontrol1b(&pc1) ;
  printf("l  0?:%i\n",pc1) ;
  pushcontrol5b( 7) ;
  pushcontrol5b(29) ;
  pushcontrol5b(23) ;
  pushcontrol5b(24) ;
  pushcontrol5b(25) ;
  pushcontrol5b(26) ;
  pushcontrol5b(27) ;

  showallstacks() ;

  pushcontrol5b(28) ;
  pushcontrol5b(21) ;
  pushcontrol5b(22) ;
  pushcontrol5b(23) ;
  pushcontrol5b(24) ;
  pushcontrol5b(25) ;
  pushcontrol5b(26) ;
  pushcontrol5b(27) ;
  pushcontrol5b(28) ;
  pushcontrol5b(29) ;

  printallbuffers() ;

  popcontrol5b(&pc3) ;
  printf("29?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("28?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("27?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("26?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("25?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("24?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("23?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("22?:%i\n",pc3) ;
  popcontrol5b(&pc3) ;
  printf("21?:%i\n",pc3) ;

  showallstacks() ;

  lookcontrol5b(&pc1) ;
  printf("L 28?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("28?:%i\n",pc1) ;

  showallstacks() ;

  popcontrol5b(&pc1) ;
  printf("27?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("26?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("25?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("24?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("23?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf("29?:%i\n",pc1) ;
  popcontrol5b(&pc1) ;
  printf(" 7?:%i\n",pc1) ;
  popinteger4(&pa) ;
  printf("-1:%i\n",pa) ;

  showallstacks() ;

  lookcontrol5b(&pc1) ;
  printf("L 14?:%i\n",pc1) ;
  lookcontrol1b(&pc1) ;
  printf("L  0?:%i\n",pc1) ;
  lookcontrol3b(&pc1) ;
  printf("L  4?:%i\n",pc1) ;

  showallstacks() ;

  popcontrol5b(&pc1) ;
  printf("14?:%i\n",pc1) ;
  popcontrol1b(&pc1) ;
  printf(" 0?:%i\n",pc1) ;
  popcontrol3b(&pc1) ;
  printf(" 4?:%i\n",pc1) ;
  popcontrol1b(&pc1) ;
  printf(" 1?:%i\n",pc1) ;
  popreal8array(PY,10) ;
  //printf("y:%f\n",PY) ;
  popreal8(&px) ;
  printf("-1.0:%f\n",px) ;

  showallstacks() ;
}
