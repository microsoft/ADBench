#pragma once

#include <stdlib.h>
#include <time.h>

/** Timing */

typedef struct timer_t2 {
	clock_t start;
} timer_t2;

timer_t2 tic();

void toc(timer_t2 t, char* s);

timer_t2 tic() {
	timer_t2 res;
	res.start = clock();
	return res;
}

void toc(timer_t2 t, char* s) {
	clock_t end = clock();
	float milliseconds = (float)(end - t.start) * 1000.0 / CLOCKS_PER_SEC;
	printf("%s -- %d (ms)\n", s, (int)milliseconds);
}

float toc2(timer_t2 t) {
	clock_t end = clock();
	float milliseconds = (float)(end - t.start) * 1000.0 / CLOCKS_PER_SEC;
	// printf("%s -- %d (ms)\n", s, (int)milliseconds);
	return milliseconds;
}

