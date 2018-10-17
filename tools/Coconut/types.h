#pragma once

typedef int index_t;
typedef double number_t;
typedef struct array_number_t_struct {
	number_t* arr;
	int length;
}* array_number_t;
typedef struct array_array_number_t {
	array_number_t* arr;
	int length;
}* array_array_number_t;
typedef struct array_array_array_number_t {
	array_array_number_t* arr;
	int length;
}* array_array_array_number_t;

typedef int card_t;
typedef struct matrix_shape_t {
  card_t elem;
  card_t card;
} matrix_shape_t;
typedef struct matrix3d_shape_t {
  matrix_shape_t elem;
  card_t card;
} matrix3d_shape_t;
typedef struct tuple_number_t_number_t {
  number_t _1;
  number_t _2;
} tuple_number_t_number_t;
typedef struct tuple_card_t_card_t {
  card_t _1;
  card_t _2;
} tuple_card_t_card_t;
typedef struct tuple_array_number_t_array_number_t {
  array_number_t _1;
  array_number_t _2;
} tuple_array_number_t_array_number_t;

typedef union value_t {
	card_t card_t_value;
	matrix_shape_t matrix_shape_t_value;
	matrix3d_shape_t matrix3d_shape_t_value;
	number_t number_t_value;
	array_number_t array_number_t_value;
	array_array_number_t array_array_number_t_value;
	array_array_array_number_t array_array_array_number_t_value;
} value_t;

typedef int bool_t;

typedef void* storage_t;

typedef char* string_t;

typedef value_t (*lambda_t)();

typedef void* env_t;

typedef int empty_env_t;

typedef struct closure_t {
	lambda_t lam;
	env_t env;
} closure_t;

typedef unsigned long long int memory_size_t;
