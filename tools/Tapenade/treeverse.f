C                   TREEVERSE MECHANISM V2
C                  ========================

c New version of TreeVerse that does not store the entire
c reversal sequence, but rather uses a stack automaton to
c generate the reversal actions one at a time.
c Allows for nested calls to Treeverse, i.e.
C nested iterative loops that use treeverse.
c Uses a small enough stack,
c allowing for 5 nested calls to TRV_INIT,
c and for a cumulated number of snapshots of 99.

c Usage:
c Call TRV_INIT(length, nbSnap, firstStep)
c  giving to it:
c   -- the length  of the sequence you need to inverse, including the
c     last step, the one that exits. E.g "do i=1,10" has length 11 !!
c   -- the number of snapshots your machine can accomodate,
c   -- the index of the first step in the sequence you need to inverse.
c Then repeated calls to TRV_NEXT_ACTION(action, step)
c  return the successive actions the treeverse loop must perform.
c  Also return in "step" the time step on which the action operates.
c  When all actions are done, TRV_NEXT_ACTION returns .FALSE.

c Global memory used to remember the state
c when the stack automaton runs:
c -STACK1 (one level (index is1) per nested treeverse session) :
c   STACK1(1,is1): index of initial level in STACK2 for this session
c   STACK1(2,is1): max number of snapshots allowed for this session
c   STACK1(3,is1): offset for step numbers in this session
c -STACK2 (one level (index is2) per nested (simultaneous) snapshot) :
c   STACK2(1,is2): number of steps to be reversed by this snapshot level
c   STACK2(2,is2): rank of the current step in STACK2(1,is2)
c   STACK2(3,is2): rank of the chosen recursive cut in STACK2(1,is2)
      BLOCK DATA TRV_GLOBAL_DATA
      INTEGER STACK1(3,5), is1, STACK2(3,99), is2
      COMMON /TRV_GLOBALS/ STACK1, is1, STACK2, is2
      DATA is1/0/
      DATA is2/0/
      END

c Initialize one nested session of treeverse commands,
c  using at most "nbSnap" snapshots, to reverse a sequence
c  of length "length", in which the first step in numbered "firstStep"
c Does not alter its arguments, but modifies STACK1 and STACK2.
      SUBROUTINE TRV_INIT(length, nbSnap, firstStep)
      IMPLICIT NONE
      INTEGER nbSnap, length, firstStep
      INTEGER STACK1(3,5), is1, STACK2(3,99), is2
      COMMON /TRV_GLOBALS/ STACK1, is1, STACK2, is2

      IF (length.le.0) THEN
         PRINT*,"Error: Cannot reverse a sequence of length ", length
         STOP
      ELSE IF (nbSnap.eq.0.and.length.ge.2) THEN
         PRINT*,"Error: Cannot reverse a sequence of length ", length,
     +        " with no snapshot"
         STOP
      ELSE IF (is1.ge.5.or.is2+nbsnap+1.ge.99) THEN
         PRINT*,"Error: Treeverse memory exceeded !"
         STOP
      ELSE
         is1 = is1+1
         is2 = is2+1
         STACK1(1,is1) = is2
         STACK1(2,is1) = nbSnap
         STACK1(3,is1) = firstStep
         STACK2(1,is2) = length
         STACK2(2,is2) = 0
         STACK2(3,is2) = 0
      END IF
      END

c Finds the next action in the process of reversing the current
c sequence of steps, i.e. running the current treeverse session.
c Overwrites "action" withthis next action to perform,
c and overwrites step with the index of the iteration step
c that corresponds to this action. Also returns .TRUE. if there
c is such an action waiting, and .FALSE. otherwise, i.e. the
c current reversal session is terminated.
      LOGICAL FUNCTION TRV_NEXT_ACTION(action, step)
      IMPLICIT NONE
      INTEGER action, step, i
      INTEGER STACK1(3,5), is1, STACK2(3,99), is2
      COMMON /TRV_GLOBALS/ STACK1, is1, STACK2, is2
      INTEGER PUSHSNAP, LOOKSNAP, POPSNAP, ADVANCE, FIRSTTURN, TURN
      PARAMETER (PUSHSNAP=1)
      PARAMETER (LOOKSNAP=2)
      PARAMETER (POPSNAP=3)
      PARAMETER (ADVANCE=4)
      PARAMETER (FIRSTTURN=5)
      PARAMETER (TURN=6)

c Part "only for debug":
c      PRINT*, ""
c      PRINT*, "STACK1:"
c      DO i=is1,1,-1
c         WRITE(*,910) STACK1(2,i), STACK1(1,i), STACK1(3,i)
c      ENDDO
c      PRINT*, "-------------------"
c      PRINT*, "STACK2:"
c      DO i=is2,1,-1
c         WRITE(*,920) i,STACK2(1,i), STACK2(2,i), STACK2(3,i)
c      ENDDO
c      PRINT*, "-------------------"
c 910  format(i2," snapshots, stack2 bottom:",i2," (offset:",i3,")")
c 920  format(i2,": R( ,",i3,") ",i3,"/",i3)
c End of "only for debug" part

      IF (STACK2(1,is2).le.0.and.is2.eq.STACK1(1,is1)) THEN
c If we are at the top snapshot level and no step remains to be
c reversed, then this inversion session is terminated.
c Pop to the enclosing inversion session. Return .FALSE.
         step = -1
         action = -1
         is1 = is1-1
         is2 = is2-1
         TRV_NEXT_ACTION = .FALSE.
      ELSE
c compute the index of the step to which the next action
c corresponds or will apply:
         step = 1 ;
         DO i=STACK1(1,is1)+1,is2
            step = step+STACK2(2,i)
         ENDDO
         IF (STACK2(2,is2).eq.-1) THEN
c If the present position is -1, i.e. the current state does not
c correspond to the next time step we are going to execute,
c then take the correct state back from the snapshot.
            IF (STACK2(1,is2).eq.1) THEN
c POP the snapshot we are at last reversing the 1st step after it...
               action = POPSNAP
            ELSE
c ... otherwise only LOOK at the snapshot, and keep it for later use.
               action = LOOKSNAP
            ENDIF
            STACK2(2,is2) = 0
         ELSE
c Now the current state corresponds to the next time step to run on.
            IF (STACK2(2,is2).eq.STACK2(1,is2)-1) THEN
c if the current position is just before the end of the current
c subsequence to reverse by this snapshot level. Then just TURN ...
               IF (step.eq.STACK2(1,STACK1(1,is1))) THEN 
                  action = FIRSTTURN
               ELSE
                  action = TURN
               ENDIF
c ... and update the stack, popping the current snapshot level
c if its work is finished, i.e. its remaining length to reverse is 0.
c Attention do not pop the initial level of the current session.
               IF (STACK2(2,is2).eq.0.and.is2.gt.STACK1(1,is1)) THEN
                  is2 = is2-1
                  STACK2(1,is2) = STACK2(3,is2)
               ELSE
                  STACK2(1,is2) = STACK2(2,is2)
               ENDIF
c mark that the current state in memory is out of date
               STACK2(2,is2) = -1
c compute the new position for the deeper level snapshot
               CALL TRV_SETCUT()
            ELSE
               IF (STACK2(2,is2).eq.STACK2(3,is2)) THEN
c if we just reached the end of this level advance sequence,
c then me must PUSH a snapshot and begin a new nested level of
c snapshot in the current reversal session.
                  action = PUSHSNAP
                  is2 = is2+1
                  STACK2(1,is2) = STACK2(1,is2-1)-STACK2(2,is2-1)
                  STACK2(2,is2) = 0
                  CALL TRV_SETCUT()
                  step = step-1
               ELSE
c else we still need to ADVANCE to reach the next checkpoint
                  action = ADVANCE
                  STACK2(2,is2) = STACK2(2,is2)+1
               ENDIF
            ENDIF
         ENDIF
         TRV_NEXT_ACTION = .TRUE.
      ENDIF
      END

c Find the index of the next CKP cut at the current checkpoint level.
c Store this index into the current STACK2(3, is2).
c Computation depends on the current length to reverse STACK2(1, is2)
c and of the current number of available snapshots, computed as
c STACK1(2,is1)-(is2-STACK1(1,is1))+1, i.e. the initial number of
c snapshots for this session, minus the number of used snapshots,
c i.e. the number of snapshot levels pushed onto STACK2 (minus 1).
c Algorithm is first to find "minRecomp", the minimum number of 
c  recomputations that allow reversing a sequence of this "length",
c  i.e. such that eta(nbSnap,minRecomp) is greater or equal to length.
c By def, eta(nbSnap,recomp)=(nbSnap+recomp)!/(nbSnap!*recomp!)
c Then this "minRecomp" defines the proportion of the length
c which is before the CKP cut, which is
c  eta(nbSnap,minRecomp-1)/eta(nbSnap,minRecomp) which is
c  (by definition of eta) minRecomp/(minRecomp+nbSnap).
c We find the cut index that approaches this proportion best.
c Assert: length>=1 , nbSnap>=0
c Alters the STACKs.
      SUBROUTINE TRV_SETCUT()
      IMPLICIT NONE
      INTEGER STACK1(3,5), is1, STACK2(3,99), is2
      COMMON /TRV_GLOBALS/ STACK1, is1, STACK2, is2
      INTEGER length, nbSnap, eta, minRecomp

      length = STACK2(1,is2)
      nbSnap = STACK1(2,is1)-(is2-STACK1(1,is1))+1
      IF (length.le.1) THEN
         STACK2(3,is2) = 0
      ELSE IF (nbSnap.eq.1) THEN
         STACK2(3,is2) = length-1
      ELSE
         eta = nbSnap+1
         minRecomp = 1
         DO WHILE (eta.LT.length)
            minRecomp = minRecomp+1
            eta = (eta*(nbSnap+minRecomp))/minRecomp
         END DO
         STACK2(3,is2) = (length*minRecomp)/(minRecomp+nbSnap)
         IF (STACK2(3,is2).eq.0) THEN
            STACK2(3,is2) = 1
         ELSE IF (STACK2(3,is2).ge.length) THEN
            STACK2(3,is2) = length-1
         END IF
      ENDIF
      END

      SUBROUTINE TRV_RESIZE()
      IMPLICIT NONE
      INTEGER step, i
      INTEGER STACK1(3,5), is1, STACK2(3,99), is2
      COMMON /TRV_GLOBALS/ STACK1, is1, STACK2, is2

      step = 1 ;
      DO i=STACK1(1,is1)+1,is2
         step = step+STACK2(2,i)
      ENDDO
      WRITE(*,930) "Binomial iteration exits on step",step-1,
     +     " before expected",STACK2(1,STACK1(1,is1))
 930  format(a,i6,a,i6)
      STACK2(1,STACK1(1,is1)) = step-1
      STACK2(1,is2) = STACK2(2,is2)
      STACK2(2,is2) = STACK2(2,is2)-1
      END
