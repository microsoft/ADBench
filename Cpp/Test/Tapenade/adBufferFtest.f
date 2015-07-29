      program adbufferftest
      REAL*8 x,Y(10),px,PY(10)
      INTEGER*8 a,B(20),pa,PB(20)
      INTEGER pc1,pc2,pc3,pc4
      LOGICAL pb1,pb2,pb3
      CHARACTER CC1(3),PCC1(3),PCC2(2)
      INTEGER i,j,k
c
      x = -1.0
      do i=1,10
         Y(i) = i*1.1
      enddo
      a = -1
      do i=1,20
         B(i) = i
      enddo
      CC1(1)='a'
      CC1(2)='b'
      CC1(3)='c'      
c
      call showallstacks()

      call PUSHREAL8(x)
      call PUSHCHARACTERARRAY(CC1,2)
      call PUSHREAL8ARRAY(Y,10)
      call PUSHCONTROL1B(1)
      call PUSHBOOLEAN(.FALSE.)
      call PUSHCONTROL3B(4)
      call PUSHBOOLEAN(.TRUE.)
      call PUSHCONTROL1B(0)
      call PUSHCONTROL5B(14)

      call PUSHBOOLEAN(.TRUE.)
      call PUSHINTEGER8(a)
      call PUSHCHARACTERARRAY(CC1,3)
      call PUSHINTEGER8ARRAY(B,20)

      call showallstacks()

      call POPINTEGER8ARRAY(PB,20)
      print *,'B:',PB

      call LOOKCHARACTERARRAY(PCC1,3)
      print *,'l CC1:',PCC1
      call LOOKINTEGER8(pa)
      print *,'l -1:',pa
      call LOOKBOOLEAN(pb1)
      print *,'l true:',pb1
      call LOOKCONTROL5B(pc1)
      print *,'l 14?:',pc1
      call LOOKCONTROL1B(pc1)
      print *,'l  0?:',pc1
      call PUSHCONTROL5B(7)
      call PUSHCONTROL5B(8)
      call PUSHCONTROL5B(9)
      call PUSHCONTROL5B(10)
      call PUSHCONTROL5B(11)
      call PUSHCONTROL5B(12)
      call PUSHCONTROL5B(13)
      call PUSHCONTROL5B(14)
      call PUSHCONTROL5B(15)
      call PUSHCONTROL5B(16)
      call PUSHCONTROL5B(17)
      call PUSHCONTROL5B(18)
      call PUSHCONTROL5B(19)
      call PUSHCONTROL5B(20)
      call PUSHCONTROL5B(21)
      call PUSHCONTROL5B(22)
      call PUSHCONTROL5B(23)
      call PUSHCONTROL5B(24)
      call PUSHCONTROL5B(25)
      call PUSHCONTROL5B(26)
      call PUSHCONTROL5B(27)

      call PUSHCONTROL5B(28)

      call PRINTALLBUFFERS()

      call LOOKCONTROL5B(pc1)
      print *,'L 28?:',pc1
      call POPCONTROL5B(pc1)
      print *,'28?:',pc1

      call POPCONTROL5B(pc1)
      print *,'27?:',pc1
      call POPCONTROL5B(pc1)
      print *,'26?:',pc1
      call POPCONTROL5B(pc1)
      print *,'25?:',pc1
      call POPCONTROL5B(pc1)
      print *,'24?:',pc1
      call POPCONTROL5B(pc1)
      print *,'23?:',pc1
      call POPCONTROL5B(pc1)
      print *,'22?:',pc1
      call POPCONTROL5B(pc1)
      print *,'21?:',pc1
      call POPCONTROL5B(pc1)
      print *,'20?:',pc1
      call POPCONTROL5B(pc1)
      print *,'19?:',pc1
      call POPCONTROL5B(pc1)
      print *,'18?:',pc1
      call POPCONTROL5B(pc1)
      print *,'17?:',pc1
      call POPCONTROL5B(pc1)
      print *,'16?:',pc1
      call POPCONTROL5B(pc1)
      print *,'15?:',pc1
      call POPCONTROL5B(pc1)
      print *,'14?:',pc1
      call POPCONTROL5B(pc1)
      print *,'13?:',pc1
      call POPCONTROL5B(pc1)
      print *,'12?:',pc1
      call POPCONTROL5B(pc1)
      print *,'11?:',pc1
      call POPCONTROL5B(pc1)
      print *,'10?:',pc1
      call POPCONTROL5B(pc1)
      print *,' 9?:',pc1
      call POPCONTROL5B(pc1)
      print *,' 8?:',pc1
      call POPCONTROL5B(pc1)
      print *,' 7?:',pc1
      call POPCHARACTERARRAY(PCC1,3)
      print *,'CC1:',PCC1
      call POPINTEGER8(pa)
      print *,'-1:',pa
      call POPBOOLEAN(pb1)
      print *,'true:',pb1

      call LOOKCONTROL5B(pc1)
      print *,'L 14?:',pc1
      call LOOKCONTROL1B(pc1)
      print *,'L  0?:',pc1
      call LOOKBOOLEAN(pb1)
      print *,'L true:',pb1
      call LOOKCONTROL3B(pc1)
      print *,'L  4?:',pc1

      call POPCONTROL5B(pc1)
      print *,'14?:',pc1
      call POPCONTROL1B(pc1)
      print *,' 0?:',pc1
      call POPBOOLEAN(pb1)
      print *,'true:',pb1
      call POPCONTROL3B(pc1)
      print *,' 4?:',pc1
      call POPBOOLEAN(pb1)
      print *,'false:',pb1
      call POPCONTROL1B(pc1)
      print *,' 1?:',pc1
      call POPREAL8ARRAY(PY,10)
      print *,'y:',py
      call POPCHARACTERARRAY(PCC2,2)
      print *,'CC2:',PCC2
      call POPREAL8(px)
      print *,'-1.0:',px

      call showallstacks()

      END
