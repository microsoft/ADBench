      program treeverseTest
      IMPLICIT NONE
      INTEGER nstp, nsnp, action,step
      LOGICAL TRV_NEXT_ACTION
      INTEGER nbadv, nbturn, nbpush, nblook, nbpop

      nbadv  = 0
      nbturn = 0
      nbpush = 0
      nblook = 0
      nbpop  = 0
      PRINT*,'Nb of time steps: '
      READ *,nstp
      PRINT*,'Nb of  snapshots: '
      READ *,nsnp
      PRINT*,'REVERSING ',nstp,' STEPS WITH ',nsnp,' SNAPSHOTS:'
      call TRV_INIT(nstp, nsnp, 1)
      DO WHILE (TRV_NEXT_ACTION(action,step))
         IF (action.eq.1) THEN
            WRITE(*,910) '[',action,'] PUSH SNAPSHOT    ',step
            nbpush = nbpush+1
         ELSE IF (action.eq.2) THEN
            WRITE(*,910) '[',action,'] LOOK SNAPSHOT    ',step
            nblook = nblook+1
         ELSE IF (action.eq.3) THEN
            WRITE(*,910) '[',action,'] POP SNAPSHOT     ',step
            nbpop = nbpop+1
         ELSE IF (action.eq.4) THEN
            WRITE(*,910) '[',action,'] ADVANCE ONE STEP ',step
            nbadv = nbadv+1
         ELSE IF (action.eq.5) THEN
            WRITE(*,910) '[',action,'] FIRST TURN       ',step
            nbturn = nbturn+1
         ELSE IF (action.eq.6) THEN
            WRITE(*,910) '[',action,'] TURN             ',step
            nbturn = nbturn+1
         ELSE
            WRITE(*,910) '[',action,'] ??               ',step
         ENDIF

c         IF (step.eq.8.and.action.eq.4) THEN
c            WRITE(*,*) '  =============> step 8: TRV_RESIZE() !!!'
c            CALL TRV_RESIZE()
c         ENDIF

      ENDDO
      WRITE(*,920) 'push:',nbpush,' look:',nblook,' pop:',nbpop,
     +     ' advance:',nbadv,' turn:',nbturn
 910  format(a1,i1,a19,i3)
 920  format(a5,i6,a6,i6,a5,i6,a9,i6,a6,i5)
      END
