# $Id: Makefile 3922 2011-05-19 08:54:39Z llh $

FC=gfortran -g
CC=gcc -g

all : testMemSize adStack.o adBuffer.o profile.o dpStack.o dpTest.o ddTest.o validityTest.o

profile.o: profile.c
	$(CC) -c profile.c

testMemSizef.o : testMemSizef.f
	$(FC) -c testMemSizef.f

testMemSizec.o : testMemSizec.c
	$(CC) -c testMemSizec.c

testMemSize : testMemSizef.o testMemSizec.o
	$(FC) testMemSizef.o testMemSizec.o -o testMemSize

adBuffer.o : adBuffer.f
	$(FC) -c adBuffer.f

adStack.o : adStack.c
	$(CC) -c adStack.c

dpStack.o : dpStack.c
	$(CC) -c dpStack.c

dpTest.o : dpTest.f
	$(FC) -c dpTest.f

validityTest.o : validityTest.f
	$(FC) -c validityTest.f

treeverseFtest : treeverseFtest.f treeverse.f
	$(FC) -c treeverseFtest.f
	$(FC) -c treeverse.f
	$(FC) treeverseFtest.o treeverse.o -o treeverseFtest

treeverseCtest : treeverseCtest.c treeverse.c treeverse.h
	$(CC) -c treeverse.c
	$(CC) -c treeverseCtest.c
	$(CC) treeverseCtest.o treeverse.o -o treeverseCtest

adBufferFtest : adStack.c adBuffer.f adBufferFtest.f
	$(FC) $^ -o $@

adBufferCtest : adStack.c adBuffer.c adBufferCtest.c
	$(FC) $^ -o $@

clean :
	-rm -f .*~ *.o testMemSize adBufferFtest treeverseCtest treeverseFtest
