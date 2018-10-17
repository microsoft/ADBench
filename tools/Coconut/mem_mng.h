#pragma once

#include <stdio.h>
#include <assert.h>
#include "types.h"
#ifdef GC
#include "gc.h"
#endif

#define INIT_HEAP_SIZE (1 << 20)
#define ALLIGN_BY_16(x) (((((x) + 15) >> 4) << 4))
#define MAX_HEAP_SIZE ((memory_size_t)(1) << 31)

typedef struct heap_t { 
  storage_t storage; 
  memory_size_t free_index; 
  memory_size_t size; 
} heap_t; 

storage_t try_allocate(memory_size_t size) {
  storage_t storage = malloc(size);
  if(storage == NULL) {
    fprintf(stderr, "Cannot allocate buffer of size %llu\n", size);
    exit(1);
  }
  return storage;
}

heap_t initHeap(memory_size_t size) {
  heap_t heap;
  heap.storage = try_allocate(size);
  heap.free_index = 0;
  heap.size = size;
  return heap;
}

heap_t heapObject;
memory_size_t increase_rate;

storage_t bulk_alloc(memory_size_t size) {
  memory_size_t aligned_size = ALLIGN_BY_16(size);
  memory_size_t new_free_index = heapObject.free_index + aligned_size;
  if (new_free_index >= heapObject.size) {
    increase_rate = heapObject.size < INIT_HEAP_SIZE ? INIT_HEAP_SIZE : increase_rate * 2;
    memory_size_t new_size = heapObject.size + increase_rate;
    new_size = new_size < new_free_index ? heapObject.size + aligned_size : new_size;
    // printf("%lld < %lld\n", new_size + heapObject.size * 2, MAX_HEAP_SIZE);
    new_size = (new_size + heapObject.size * 2) < MAX_HEAP_SIZE ? new_size : new_size * 5 / 8;

    heap_t oldHeapObject = heapObject;
    // fprintf(stderr, "Increased the size of heap into %llu, old size: %llu, asked size: %llu, last given index: %llu!\n", new_size, oldHeapObject.size, size, oldHeapObject.free_index); 
    heapObject = initHeap(new_size);
    // heapObject.free_index = oldHeapObject.free_index;
    // memcpy(heapObject.storage, oldHeapObject.storage, heapObject.free_index);
    // free(oldHeapObject.storage);
  } 
  storage_t allocatedStorage = (void *)((memory_size_t)heapObject.storage + heapObject.free_index);
  heapObject.free_index = heapObject.free_index + aligned_size;
  return allocatedStorage;
}

void bulk_free(storage_t storage, memory_size_t size) {
  memory_size_t aligned_size = ALLIGN_BY_16(size);
  heapObject.free_index -= aligned_size;
  assert(heapObject.free_index >= 0);
  // if(heapObject.free_index < 0)
  //  heapObject.free_index = 0;
}

storage_t storage_alloc(memory_size_t size) {
#ifdef BUMP
  return bulk_alloc(size);
#else
#ifdef GC
  return GC_malloc(size);
#else
  return malloc(size);
#endif
#endif
}

void storage_free(storage_t storage, memory_size_t size) {
#ifdef BUMP
  bulk_free(storage, size);
#else
  free(storage);
#endif
}
