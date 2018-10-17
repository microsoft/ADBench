#ifndef __LINALG_STORAGED_H__ 
#define __LINALG_STORAGED_H__ 
#include "fsharp.h"
#include <stdio.h>
#include <math.h>

card_t TOP_LEVEL_linalg_rows_shp(matrix_shape_t m_shp) {
	
	return m_shp.card;
}


card_t TOP_LEVEL_linalg_rows_dps(storage_t stgVar1, array_array_number_t m_dps, matrix_shape_t m_shp) {
	card_t macroDef3 = m_dps->length;
	return macroDef3;
}

card_t TOP_LEVEL_linalg_cols_shp(matrix_shape_t m_shp) {
	
	return m_shp.elem;
}


card_t TOP_LEVEL_linalg_cols_dps(storage_t stgVar4, array_array_number_t m_dps, matrix_shape_t m_shp) {
	card_t size9 = width_card_t(m_shp.elem);
	array_number_t stgVar5 = storage_alloc(size9);
	card_t macroDef8;card_t macroDef7 = m_dps->arr[0]->length;
	macroDef8 = macroDef7;;
	storage_free(stgVar5, size9);
	return macroDef8;
}

card_t TOP_LEVEL_linalg_vectorMap_shp(closure_t f_shp, card_t v_shp) {
	
	return v_shp;
}


array_number_t TOP_LEVEL_linalg_vectorMap_dps(storage_t stgVar10, closure_t f_dps, array_number_t v_dps, closure_t f_shp, card_t v_shp) {
	card_t macroDef15 = v_dps->length;
	array_number_t macroDef16 = (array_number_t)stgVar10;
		macroDef16->length=macroDef15;
		macroDef16->arr=(number_t*)(STG_OFFSET(macroDef16, VECTOR_HEADER_BYTES));
		storage_t stgVar12 = macroDef16;
		for(int i_dps = 0; i_dps < macroDef16->length; i_dps++){
			
			macroDef16->arr[i_dps] = f_dps.lam(f_dps.env, stgVar12, v_dps->arr[i_dps], 0).number_t_value;;
			stgVar12 = STG_OFFSET(stgVar12, sizeof(number_t));
		}
	return macroDef16;
}

card_t TOP_LEVEL_linalg_vectorRange_shp(card_t s_shp, card_t e_shp) {
	
	return ((e_shp) - (s_shp)) + (1);
}


array_number_t TOP_LEVEL_linalg_vectorRange_dps(storage_t stgVar17, card_t s_dps, card_t e_dps, card_t s_shp, card_t e_shp) {
	array_number_t macroDef19 = (array_number_t)stgVar17;
		macroDef19->length=((e_dps) - (s_dps)) + (1);
		macroDef19->arr=(number_t*)(STG_OFFSET(macroDef19, VECTOR_HEADER_BYTES));
		storage_t stgVar18 = macroDef19;
		for(int i_dps = 0; i_dps < macroDef19->length; i_dps++){
			
			macroDef19->arr[i_dps] = (double)(((s_dps)) + (i_dps));;
			stgVar18 = STG_OFFSET(stgVar18, sizeof(number_t));
		}
	return macroDef19;
}

card_t TOP_LEVEL_linalg_vectorSlice_shp(card_t size_shp, card_t offset_shp, card_t v_shp) {
	
	return size_shp;
}


array_number_t TOP_LEVEL_linalg_vectorSlice_dps(storage_t stgVar20, card_t size_dps, index_t offset_dps, array_number_t v_dps, card_t size_shp, card_t offset_shp, card_t v_shp) {
	array_number_t macroDef23 = (array_number_t)stgVar20;
		macroDef23->length=size_dps;
		macroDef23->arr=(number_t*)(STG_OFFSET(macroDef23, VECTOR_HEADER_BYTES));
		storage_t stgVar21 = macroDef23;
		for(int i_dps = 0; i_dps < macroDef23->length; i_dps++){
			
			macroDef23->arr[i_dps] = v_dps->arr[(i_dps) + (offset_dps)];;
			stgVar21 = STG_OFFSET(stgVar21, sizeof(number_t));
		}
	return macroDef23;
}

matrix_shape_t TOP_LEVEL_linalg_matrixSlice_shp(card_t size_shp, card_t offset_shp, matrix_shape_t m_shp) {
	
	return nested_shape_card_t(m_shp.elem, size_shp);
}


array_array_number_t TOP_LEVEL_linalg_matrixSlice_dps(storage_t stgVar24, card_t size_dps, index_t offset_dps, array_array_number_t m_dps, card_t size_shp, card_t offset_shp, matrix_shape_t m_shp) {
	array_array_number_t macroDef27 = (array_array_number_t)stgVar24;
		macroDef27->length=size_dps;
		macroDef27->arr=(array_number_t*)(STG_OFFSET(macroDef27, VECTOR_HEADER_BYTES));
		storage_t stgVar25 = (STG_OFFSET(macroDef27, MATRIX_HEADER_BYTES(size_dps)));
		for(int i_dps = 0; i_dps < macroDef27->length; i_dps++){
			
			macroDef27->arr[i_dps] = m_dps->arr[(i_dps) + (offset_dps)];;
			stgVar25 = STG_OFFSET(stgVar25, VECTOR_ALL_BYTES(macroDef27->arr[i_dps]->length));
		}
	return macroDef27;
}

matrix_shape_t TOP_LEVEL_linalg_matrixMap_shp(closure_t f_shp, matrix_shape_t m_shp) {
	
	return nested_shape_card_t(f_shp.lam(f_shp.env, m_shp.elem).card_t_value, m_shp.card);
}


array_array_number_t TOP_LEVEL_linalg_matrixMap_dps(storage_t stgVar28, closure_t f_dps, array_array_number_t m_dps, closure_t f_shp, matrix_shape_t m_shp) {
	card_t macroDef33 = m_dps->length;
	array_array_number_t macroDef35 = (array_array_number_t)stgVar28;
		macroDef35->length=macroDef33;
		macroDef35->arr=(array_number_t*)(STG_OFFSET(macroDef35, VECTOR_HEADER_BYTES));
		storage_t stgVar30 = (STG_OFFSET(macroDef35, MATRIX_HEADER_BYTES(macroDef33)));
		for(int i_dps = 0; i_dps < macroDef35->length; i_dps++){
			card_t size36 = width_card_t(m_shp.elem);
	array_number_t stgVar31 = storage_alloc(size36);
	array_number_t macroDef34;
	macroDef34 = f_dps.lam(f_dps.env, stgVar30, m_dps->arr[i_dps], m_shp.elem).array_number_t_value;;
	storage_free(stgVar31, size36);
			macroDef35->arr[i_dps] = macroDef34;;
			stgVar30 = STG_OFFSET(stgVar30, VECTOR_ALL_BYTES(macroDef35->arr[i_dps]->length));
		}
	return macroDef35;
}

card_t TOP_LEVEL_linalg_matrixMapToVector_shp(closure_t f_shp, matrix_shape_t m_shp) {
	
	return m_shp.card;
}


array_number_t TOP_LEVEL_linalg_matrixMapToVector_dps(storage_t stgVar37, closure_t f_dps, array_array_number_t m_dps, closure_t f_shp, matrix_shape_t m_shp) {
	card_t macroDef42 = m_dps->length;
	array_number_t macroDef44 = (array_number_t)stgVar37;
		macroDef44->length=macroDef42;
		macroDef44->arr=(number_t*)(STG_OFFSET(macroDef44, VECTOR_HEADER_BYTES));
		storage_t stgVar39 = macroDef44;
		for(int i_dps = 0; i_dps < macroDef44->length; i_dps++){
			card_t size45 = width_card_t(m_shp.elem);
	array_number_t stgVar40 = storage_alloc(size45);
	number_t macroDef43;
	macroDef43 = f_dps.lam(f_dps.env, stgVar39, m_dps->arr[i_dps], m_shp.elem).number_t_value;;
	storage_free(stgVar40, size45);
			macroDef44->arr[i_dps] = macroDef43;;
			stgVar39 = STG_OFFSET(stgVar39, sizeof(number_t));
		}
	return macroDef44;
}

card_t TOP_LEVEL_linalg_vectorMap2_shp(closure_t f_shp, card_t v1_shp, card_t v2_shp) {
	
	return v1_shp;
}


array_number_t TOP_LEVEL_linalg_vectorMap2_dps(storage_t stgVar46, closure_t f_dps, array_number_t v1_dps, array_number_t v2_dps, closure_t f_shp, card_t v1_shp, card_t v2_shp) {
	card_t macroDef53 = v1_dps->length;
	array_number_t macroDef54 = (array_number_t)stgVar46;
		macroDef54->length=macroDef53;
		macroDef54->arr=(number_t*)(STG_OFFSET(macroDef54, VECTOR_HEADER_BYTES));
		storage_t stgVar48 = macroDef54;
		for(int i_dps = 0; i_dps < macroDef54->length; i_dps++){
			
			macroDef54->arr[i_dps] = f_dps.lam(f_dps.env, stgVar48, v1_dps->arr[i_dps], v2_dps->arr[i_dps], 0, 0).number_t_value;;
			stgVar48 = STG_OFFSET(stgVar48, sizeof(number_t));
		}
	return macroDef54;
}

matrix_shape_t TOP_LEVEL_linalg_matrixMap2_shp(closure_t f_shp, matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	
	return nested_shape_card_t(f_shp.lam(f_shp.env, m1_shp.elem, m2_shp.elem).card_t_value, m1_shp.card);
}


array_array_number_t TOP_LEVEL_linalg_matrixMap2_dps(storage_t stgVar55, closure_t f_dps, array_array_number_t m1_dps, array_array_number_t m2_dps, closure_t f_shp, matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	card_t macroDef62 = m1_dps->length;
	array_array_number_t macroDef65 = (array_array_number_t)stgVar55;
		macroDef65->length=macroDef62;
		macroDef65->arr=(array_number_t*)(STG_OFFSET(macroDef65, VECTOR_HEADER_BYTES));
		storage_t stgVar57 = (STG_OFFSET(macroDef65, MATRIX_HEADER_BYTES(macroDef62)));
		for(int i_dps = 0; i_dps < macroDef65->length; i_dps++){
			card_t size67 = width_card_t(m2_shp.elem);
	array_number_t stgVar59 = storage_alloc(size67);
	array_number_t macroDef64;card_t size66 = width_card_t(m1_shp.elem);
	array_number_t stgVar58 = storage_alloc(size66);
	array_number_t macroDef63;
	macroDef63 = f_dps.lam(f_dps.env, stgVar57, m1_dps->arr[i_dps], m2_dps->arr[i_dps], m1_shp.elem, m2_shp.elem).array_number_t_value;;
	storage_free(stgVar58, size66);
	macroDef64 = macroDef63;;
	storage_free(stgVar59, size67);
			macroDef65->arr[i_dps] = macroDef64;;
			stgVar57 = STG_OFFSET(stgVar57, VECTOR_ALL_BYTES(macroDef65->arr[i_dps]->length));
		}
	return macroDef65;
}

matrix3d_shape_t TOP_LEVEL_linalg_matrix3DMap2_shp(closure_t f_shp, matrix3d_shape_t m1_shp, matrix3d_shape_t m2_shp) {
	
	return nested_shape_matrix_shape_t(f_shp.lam(f_shp.env, m1_shp.elem, m2_shp.elem).matrix_shape_t_value, m1_shp.card);
}


array_array_array_number_t TOP_LEVEL_linalg_matrix3DMap2_dps(storage_t stgVar68, closure_t f_dps, array_array_array_number_t m1_dps, array_array_array_number_t m2_dps, closure_t f_shp, matrix3d_shape_t m1_shp, matrix3d_shape_t m2_shp) {
	card_t macroDef75 = m1_dps->length;
	array_array_array_number_t macroDef78 = (array_array_array_number_t)stgVar68;
		macroDef78->length=macroDef75;
		macroDef78->arr=(array_array_number_t*)(STG_OFFSET(macroDef78, VECTOR_HEADER_BYTES));
		storage_t stgVar70 = (STG_OFFSET(macroDef78, MATRIX_HEADER_BYTES(macroDef75)));
		for(int i_dps = 0; i_dps < macroDef78->length; i_dps++){
			card_t size80 = width_matrix_shape_t(m2_shp.elem);
	array_number_t stgVar72 = storage_alloc(size80);
	array_array_number_t macroDef77;card_t size79 = width_matrix_shape_t(m1_shp.elem);
	array_number_t stgVar71 = storage_alloc(size79);
	array_array_number_t macroDef76;
	macroDef76 = f_dps.lam(f_dps.env, stgVar70, m1_dps->arr[i_dps], m2_dps->arr[i_dps], m1_shp.elem, m2_shp.elem).array_array_number_t_value;;
	storage_free(stgVar71, size79);
	macroDef77 = macroDef76;;
	storage_free(stgVar72, size80);
			macroDef78->arr[i_dps] = macroDef77;;
			stgVar70 = STG_OFFSET(stgVar70, VECTOR_ALL_BYTES(macroDef78->arr[i_dps]->length));
		}
	return macroDef78;
}

matrix_shape_t TOP_LEVEL_linalg_vectorMapToMatrix_shp(closure_t f_shp, card_t arr_shp) {
	
	return nested_shape_card_t(f_shp.lam(f_shp.env, 0).card_t_value, arr_shp);
}


array_array_number_t TOP_LEVEL_linalg_vectorMapToMatrix_dps(storage_t stgVar81, closure_t f_dps, array_number_t arr_dps, closure_t f_shp, card_t arr_shp) {
	card_t macroDef86 = arr_dps->length;
	array_array_number_t macroDef87 = (array_array_number_t)stgVar81;
		macroDef87->length=macroDef86;
		macroDef87->arr=(array_number_t*)(STG_OFFSET(macroDef87, VECTOR_HEADER_BYTES));
		storage_t stgVar83 = (STG_OFFSET(macroDef87, MATRIX_HEADER_BYTES(macroDef86)));
		for(int i_dps = 0; i_dps < macroDef87->length; i_dps++){
			
			macroDef87->arr[i_dps] = f_dps.lam(f_dps.env, stgVar83, arr_dps->arr[i_dps], 0).array_number_t_value;;
			stgVar83 = STG_OFFSET(stgVar83, VECTOR_ALL_BYTES(macroDef87->arr[i_dps]->length));
		}
	return macroDef87;
}

matrix3d_shape_t TOP_LEVEL_linalg_vectorMapToMatrix3D_shp(closure_t f_shp, card_t arr_shp) {
	
	return nested_shape_matrix_shape_t(f_shp.lam(f_shp.env, 0).matrix_shape_t_value, arr_shp);
}


array_array_array_number_t TOP_LEVEL_linalg_vectorMapToMatrix3D_dps(storage_t stgVar88, closure_t f_dps, array_number_t arr_dps, closure_t f_shp, card_t arr_shp) {
	card_t macroDef93 = arr_dps->length;
	array_array_array_number_t macroDef94 = (array_array_array_number_t)stgVar88;
		macroDef94->length=macroDef93;
		macroDef94->arr=(array_array_number_t*)(STG_OFFSET(macroDef94, VECTOR_HEADER_BYTES));
		storage_t stgVar90 = (STG_OFFSET(macroDef94, MATRIX_HEADER_BYTES(macroDef93)));
		for(int i_dps = 0; i_dps < macroDef94->length; i_dps++){
			
			macroDef94->arr[i_dps] = f_dps.lam(f_dps.env, stgVar90, arr_dps->arr[i_dps], 0).array_array_number_t_value;;
			stgVar90 = STG_OFFSET(stgVar90, VECTOR_ALL_BYTES(macroDef94->arr[i_dps]->length));
		}
	return macroDef94;
}

card_t TOP_LEVEL_linalg_vectorFoldNumber_shp(closure_t f_shp, card_t z_shp, card_t range_shp) {
	
	return 0;
}


number_t TOP_LEVEL_linalg_vectorFoldNumber_dps(storage_t stgVar95, closure_t f_dps, number_t z_dps, array_number_t range_dps, closure_t f_shp, card_t z_shp, card_t range_shp) {
	card_t l_shp = range_shp;
	card_t macroDef104 = range_dps->length;
	card_t l_dps = macroDef104;
	card_t anfvar98_shp = 0;
	card_t anfvar98_dps = 0;
	number_t macroDef105 = z_dps;
	storage_t stgVar100 = stgVar95;
	for(int idx_dps = anfvar98_dps; idx_dps < l_dps; idx_dps++){
		macroDef105 = f_dps.lam(f_dps.env, stgVar100, macroDef105, range_dps->arr[idx_dps], 0, 0).number_t_value;;
	}
	return macroDef105;
}

card_t TOP_LEVEL_linalg_vectorSum_shp(card_t v_shp) {
	
	return 0;
}

typedef empty_env_t env_t_117;


value_t lambda117(env_t_117* env111, storage_t stgVar110, number_t acc_dps, number_t cur_dps, card_t acc_shp, card_t cur_shp) {
	
	value_t res;
	res.number_t_value = (acc_dps) + (cur_dps);
	return res;
}
typedef empty_env_t env_t_118;


value_t lambda118(env_t_118* env114, card_t acc_shp, card_t cur_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_linalg_vectorSum_dps(storage_t stgVar106, array_number_t v_dps, card_t v_shp) {
	env_t_117 env_t_117_value = make_empty_env(); closure_t closure113 = make_closure(lambda117, &env_t_117_value);
	env_t_118 env_t_118_value = make_empty_env(); closure_t closure116 = make_closure(lambda118, &env_t_118_value);
	return TOP_LEVEL_linalg_vectorFoldNumber_dps(stgVar106, closure113, 0, v_dps, closure116, 0, v_shp);
}

card_t TOP_LEVEL_linalg_vectorMax_shp(card_t v_shp) {
	
	return 0;
}

typedef empty_env_t env_t_131;


value_t lambda131(env_t_131* env124, storage_t stgVar123, number_t acc_dps, number_t cur_dps, card_t acc_shp, card_t cur_shp) {
	number_t ite130 = 0;
	if((acc_dps) > (cur_dps)) {
		
		ite130 = acc_dps;;
	} else {
		
		ite130 = cur_dps;;
	}
	value_t res;
	res.number_t_value = ite130;
	return res;
}
typedef empty_env_t env_t_132;


value_t lambda132(env_t_132* env127, card_t acc_shp, card_t cur_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_linalg_vectorMax_dps(storage_t stgVar119, array_number_t v_dps, card_t v_shp) {
	env_t_131 env_t_131_value = make_empty_env(); closure_t closure126 = make_closure(lambda131, &env_t_131_value);
	env_t_132 env_t_132_value = make_empty_env(); closure_t closure129 = make_closure(lambda132, &env_t_132_value);
	return TOP_LEVEL_linalg_vectorFoldNumber_dps(stgVar119, closure126, -1000, v_dps, closure129, 0, v_shp);
}
typedef empty_env_t env_t_140;


value_t lambda140(env_t_140* env137, card_t xi_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_mult_by_scalar_shp(card_t x_shp, card_t y_shp) {
	env_t_140 env_t_140_value = make_empty_env(); closure_t closure139 = make_closure(lambda140, &env_t_140_value);
	return TOP_LEVEL_linalg_vectorMap_shp(closure139, x_shp);
}

typedef struct env_t_148 {
	number_t y_dps;
} env_t_148;
env_t_148 make_env_t_148(number_t y_dps) {
	env_t_148 env;
	env.y_dps = y_dps;
	return env;
}

value_t lambda148(env_t_148* env142, storage_t stgVar136, number_t xi_dps, card_t xi_shp) {
	number_t y_dps141 = env142->y_dps;
	value_t res;
	res.number_t_value = (xi_dps) * (y_dps141);
	return res;
}
typedef empty_env_t env_t_149;


value_t lambda149(env_t_149* env145, card_t xi_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_mult_by_scalar_dps(storage_t stgVar133, array_number_t x_dps, number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_148 env_t_148_value = make_env_t_148(y_dps); closure_t closure144 = make_closure(lambda148, &env_t_148_value);
	env_t_149 env_t_149_value = make_empty_env(); closure_t closure147 = make_closure(lambda149, &env_t_149_value);
	return TOP_LEVEL_linalg_vectorMap_dps(stgVar133, closure144, x_dps, closure147, x_shp);
}
typedef empty_env_t env_t_157;


value_t lambda157(env_t_157* env154, card_t xi_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_gaxpy_shp(card_t a_shp, card_t x_shp, card_t y_shp) {
	env_t_157 env_t_157_value = make_empty_env(); closure_t closure156 = make_closure(lambda157, &env_t_157_value);
	return TOP_LEVEL_linalg_vectorMap_shp(closure156, x_shp);
}

typedef struct env_t_166 {
	number_t y_dps;
	number_t a_dps;
} env_t_166;
env_t_166 make_env_t_166(number_t y_dps,number_t a_dps) {
	env_t_166 env;
	env.y_dps = y_dps;
	env.a_dps = a_dps;
	return env;
}

value_t lambda166(env_t_166* env160, storage_t stgVar153, number_t xi_dps, card_t xi_shp) {
	number_t y_dps159 = env160->y_dps;
	number_t a_dps158 = env160->a_dps;
	value_t res;
	res.number_t_value = ((a_dps158) * (xi_dps)) + (y_dps159);
	return res;
}
typedef empty_env_t env_t_167;


value_t lambda167(env_t_167* env163, card_t xi_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_gaxpy_dps(storage_t stgVar150, number_t a_dps, array_number_t x_dps, number_t y_dps, card_t a_shp, card_t x_shp, card_t y_shp) {
	env_t_166 env_t_166_value = make_env_t_166(y_dps,a_dps); closure_t closure162 = make_closure(lambda166, &env_t_166_value);
	env_t_167 env_t_167_value = make_empty_env(); closure_t closure165 = make_closure(lambda167, &env_t_167_value);
	return TOP_LEVEL_linalg_vectorMap_dps(stgVar150, closure162, x_dps, closure165, x_shp);
}

card_t TOP_LEVEL_linalg_cross_shp(card_t a_shp, card_t b_shp) {
	
	return 3;
}


array_number_t TOP_LEVEL_linalg_cross_dps(storage_t stgVar168, array_number_t a_dps, array_number_t b_dps, card_t a_shp, card_t b_shp) {
	array_number_t macroDef184 = (array_number_t)stgVar168;
	macroDef184->length=3;
	macroDef184->arr=(number_t*)(STG_OFFSET(stgVar168, VECTOR_HEADER_BYTES));
	

	macroDef184->arr[0] = ((a_dps->arr[1]) * (b_dps->arr[2])) - ((a_dps->arr[2]) * (b_dps->arr[1]));;

	macroDef184->arr[1] = ((a_dps->arr[2]) * (b_dps->arr[0])) - ((a_dps->arr[0]) * (b_dps->arr[2]));;

	macroDef184->arr[2] = ((a_dps->arr[0]) * (b_dps->arr[1])) - ((a_dps->arr[1]) * (b_dps->arr[0]));;;
	return macroDef184;
}
typedef empty_env_t env_t_193;


value_t lambda193(env_t_193* env190, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_vectorAdd_shp(card_t x_shp, card_t y_shp) {
	env_t_193 env_t_193_value = make_empty_env(); closure_t closure192 = make_closure(lambda193, &env_t_193_value);
	return TOP_LEVEL_linalg_vectorMap2_shp(closure192, x_shp, y_shp);
}

typedef empty_env_t env_t_200;


value_t lambda200(env_t_200* env194, storage_t stgVar189, number_t x_dps0, number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.number_t_value = (x_dps0) + (y_dps0);
	return res;
}
typedef empty_env_t env_t_201;


value_t lambda201(env_t_201* env197, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_vectorAdd_dps(storage_t stgVar185, array_number_t x_dps, array_number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_200 env_t_200_value = make_empty_env(); closure_t closure196 = make_closure(lambda200, &env_t_200_value);
	env_t_201 env_t_201_value = make_empty_env(); closure_t closure199 = make_closure(lambda201, &env_t_201_value);
	return TOP_LEVEL_linalg_vectorMap2_dps(stgVar185, closure196, x_dps, y_dps, closure199, x_shp, y_shp);
}
typedef empty_env_t env_t_210;


value_t lambda210(env_t_210* env207, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_mult_vec_elementwise_shp(card_t x_shp, card_t y_shp) {
	env_t_210 env_t_210_value = make_empty_env(); closure_t closure209 = make_closure(lambda210, &env_t_210_value);
	return TOP_LEVEL_linalg_vectorMap2_shp(closure209, x_shp, y_shp);
}

typedef empty_env_t env_t_217;


value_t lambda217(env_t_217* env211, storage_t stgVar206, number_t x_dps0, number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.number_t_value = (x_dps0) * (y_dps0);
	return res;
}
typedef empty_env_t env_t_218;


value_t lambda218(env_t_218* env214, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_mult_vec_elementwise_dps(storage_t stgVar202, array_number_t x_dps, array_number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_217 env_t_217_value = make_empty_env(); closure_t closure213 = make_closure(lambda217, &env_t_217_value);
	env_t_218 env_t_218_value = make_empty_env(); closure_t closure216 = make_closure(lambda218, &env_t_218_value);
	return TOP_LEVEL_linalg_vectorMap2_dps(stgVar202, closure213, x_dps, y_dps, closure216, x_shp, y_shp);
}
typedef empty_env_t env_t_227;


value_t lambda227(env_t_227* env224, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_op_DotMultiply_shp(card_t x_shp, card_t y_shp) {
	env_t_227 env_t_227_value = make_empty_env(); closure_t closure226 = make_closure(lambda227, &env_t_227_value);
	return TOP_LEVEL_linalg_vectorMap2_shp(closure226, x_shp, y_shp);
}

typedef empty_env_t env_t_234;


value_t lambda234(env_t_234* env228, storage_t stgVar223, number_t x_dps0, number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.number_t_value = (x_dps0) * (y_dps0);
	return res;
}
typedef empty_env_t env_t_235;


value_t lambda235(env_t_235* env231, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_op_DotMultiply_dps(storage_t stgVar219, array_number_t x_dps, array_number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_234 env_t_234_value = make_empty_env(); closure_t closure230 = make_closure(lambda234, &env_t_234_value);
	env_t_235 env_t_235_value = make_empty_env(); closure_t closure233 = make_closure(lambda235, &env_t_235_value);
	return TOP_LEVEL_linalg_vectorMap2_dps(stgVar219, closure230, x_dps, y_dps, closure233, x_shp, y_shp);
}

card_t TOP_LEVEL_linalg_vectorAdd3_shp(card_t x_shp, card_t y_shp, card_t z_shp) {
	
	return TOP_LEVEL_linalg_vectorAdd_shp(TOP_LEVEL_linalg_vectorAdd_shp(x_shp, y_shp), z_shp);
}


array_number_t TOP_LEVEL_linalg_vectorAdd3_dps(storage_t stgVar236, array_number_t x_dps, array_number_t y_dps, array_number_t z_dps, card_t x_shp, card_t y_shp, card_t z_shp) {
	card_t size242 = width_card_t(TOP_LEVEL_linalg_vectorAdd_shp(x_shp, y_shp));
	array_number_t stgVar237 = storage_alloc(size242);
	array_number_t macroDef241;
	macroDef241 = TOP_LEVEL_linalg_vectorAdd_dps(stgVar236, TOP_LEVEL_linalg_vectorAdd_dps(stgVar237, x_dps, y_dps, x_shp, y_shp), z_dps, TOP_LEVEL_linalg_vectorAdd_shp(x_shp, y_shp), z_shp);;
	storage_free(stgVar237, size242);
	return macroDef241;
}
typedef empty_env_t env_t_251;


value_t lambda251(env_t_251* env248, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
card_t TOP_LEVEL_linalg_vectorSub_shp(card_t x_shp, card_t y_shp) {
	env_t_251 env_t_251_value = make_empty_env(); closure_t closure250 = make_closure(lambda251, &env_t_251_value);
	return TOP_LEVEL_linalg_vectorMap2_shp(closure250, x_shp, y_shp);
}

typedef empty_env_t env_t_258;


value_t lambda258(env_t_258* env252, storage_t stgVar247, number_t x_dps0, number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.number_t_value = (x_dps0) - (y_dps0);
	return res;
}
typedef empty_env_t env_t_259;


value_t lambda259(env_t_259* env255, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
array_number_t TOP_LEVEL_linalg_vectorSub_dps(storage_t stgVar243, array_number_t x_dps, array_number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_258 env_t_258_value = make_empty_env(); closure_t closure254 = make_closure(lambda258, &env_t_258_value);
	env_t_259 env_t_259_value = make_empty_env(); closure_t closure257 = make_closure(lambda259, &env_t_259_value);
	return TOP_LEVEL_linalg_vectorMap2_dps(stgVar243, closure254, x_dps, y_dps, closure257, x_shp, y_shp);
}
typedef empty_env_t env_t_270;


value_t lambda270(env_t_270* env267, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = TOP_LEVEL_linalg_vectorAdd_shp(x_shp0, y_shp0);
	return res;
}
matrix_shape_t TOP_LEVEL_linalg_matrixAdd_shp(matrix_shape_t x_shp, matrix_shape_t y_shp) {
	env_t_270 env_t_270_value = make_empty_env(); closure_t closure269 = make_closure(lambda270, &env_t_270_value);
	return TOP_LEVEL_linalg_matrixMap2_shp(closure269, x_shp, y_shp);
}

typedef empty_env_t env_t_277;


value_t lambda277(env_t_277* env271, storage_t stgVar264, array_number_t x_dps0, array_number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.array_number_t_value = TOP_LEVEL_linalg_vectorAdd_dps(stgVar264, x_dps0, y_dps0, x_shp0, y_shp0);
	return res;
}
typedef empty_env_t env_t_278;


value_t lambda278(env_t_278* env274, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = TOP_LEVEL_linalg_vectorAdd_shp(x_shp0, y_shp0);
	return res;
}
array_array_number_t TOP_LEVEL_linalg_matrixAdd_dps(storage_t stgVar260, array_array_number_t x_dps, array_array_number_t y_dps, matrix_shape_t x_shp, matrix_shape_t y_shp) {
	env_t_277 env_t_277_value = make_empty_env(); closure_t closure273 = make_closure(lambda277, &env_t_277_value);
	env_t_278 env_t_278_value = make_empty_env(); closure_t closure276 = make_closure(lambda278, &env_t_278_value);
	return TOP_LEVEL_linalg_matrixMap2_dps(stgVar260, closure273, x_dps, y_dps, closure276, x_shp, y_shp);
}
typedef empty_env_t env_t_289;


value_t lambda289(env_t_289* env286, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = TOP_LEVEL_linalg_mult_vec_elementwise_shp(x_shp0, y_shp0);
	return res;
}
matrix_shape_t TOP_LEVEL_linalg_matrixMultElementwise_shp(matrix_shape_t x_shp, matrix_shape_t y_shp) {
	env_t_289 env_t_289_value = make_empty_env(); closure_t closure288 = make_closure(lambda289, &env_t_289_value);
	return TOP_LEVEL_linalg_matrixMap2_shp(closure288, x_shp, y_shp);
}

typedef empty_env_t env_t_296;


value_t lambda296(env_t_296* env290, storage_t stgVar283, array_number_t x_dps0, array_number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.array_number_t_value = TOP_LEVEL_linalg_mult_vec_elementwise_dps(stgVar283, x_dps0, y_dps0, x_shp0, y_shp0);
	return res;
}
typedef empty_env_t env_t_297;


value_t lambda297(env_t_297* env293, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = TOP_LEVEL_linalg_mult_vec_elementwise_shp(x_shp0, y_shp0);
	return res;
}
array_array_number_t TOP_LEVEL_linalg_matrixMultElementwise_dps(storage_t stgVar279, array_array_number_t x_dps, array_array_number_t y_dps, matrix_shape_t x_shp, matrix_shape_t y_shp) {
	env_t_296 env_t_296_value = make_empty_env(); closure_t closure292 = make_closure(lambda296, &env_t_296_value);
	env_t_297 env_t_297_value = make_empty_env(); closure_t closure295 = make_closure(lambda297, &env_t_297_value);
	return TOP_LEVEL_linalg_matrixMap2_dps(stgVar279, closure292, x_dps, y_dps, closure295, x_shp, y_shp);
}

card_t TOP_LEVEL_linalg_sqnorm_shp(card_t x_shp) {
	
	return 0;
}

typedef empty_env_t env_t_316;


value_t lambda316(env_t_316* env303, card_t x1_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_317;


value_t lambda317(env_t_317* env306, storage_t stgVar302, number_t x1_dps, card_t x1_shp) {
	
	value_t res;
	res.number_t_value = (x1_dps) * (x1_dps);
	return res;
}
typedef empty_env_t env_t_318;


value_t lambda318(env_t_318* env309, card_t x1_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_319;


value_t lambda319(env_t_319* env312, card_t x1_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_linalg_sqnorm_dps(storage_t stgVar298, array_number_t x_dps, card_t x_shp) {
	env_t_316 env_t_316_value = make_empty_env(); closure_t closure305 = make_closure(lambda316, &env_t_316_value);
	card_t size320 = width_card_t(TOP_LEVEL_linalg_vectorMap_shp(closure305, x_shp));
	array_number_t stgVar299 = storage_alloc(size320);
	number_t macroDef315;env_t_317 env_t_317_value = make_empty_env(); closure_t closure308 = make_closure(lambda317, &env_t_317_value);
	env_t_318 env_t_318_value = make_empty_env(); closure_t closure311 = make_closure(lambda318, &env_t_318_value);
	env_t_319 env_t_319_value = make_empty_env(); closure_t closure314 = make_closure(lambda319, &env_t_319_value);
	macroDef315 = TOP_LEVEL_linalg_vectorSum_dps(stgVar298, TOP_LEVEL_linalg_vectorMap_dps(stgVar299, closure308, x_dps, closure311, x_shp), TOP_LEVEL_linalg_vectorMap_shp(closure314, x_shp));;
	storage_free(stgVar299, size320);
	return macroDef315;
}

card_t TOP_LEVEL_linalg_dot_prod_shp(card_t x_shp, card_t y_shp) {
	
	return 0;
}

typedef empty_env_t env_t_340;


value_t lambda340(env_t_340* env327, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_341;


value_t lambda341(env_t_341* env330, storage_t stgVar326, number_t x_dps0, number_t y_dps0, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.number_t_value = (x_dps0) * (y_dps0);
	return res;
}
typedef empty_env_t env_t_342;


value_t lambda342(env_t_342* env333, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_343;


value_t lambda343(env_t_343* env336, card_t x_shp0, card_t y_shp0) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_linalg_dot_prod_dps(storage_t stgVar321, array_number_t x_dps, array_number_t y_dps, card_t x_shp, card_t y_shp) {
	env_t_340 env_t_340_value = make_empty_env(); closure_t closure329 = make_closure(lambda340, &env_t_340_value);
	card_t size344 = width_card_t(TOP_LEVEL_linalg_vectorMap2_shp(closure329, x_shp, y_shp));
	array_number_t stgVar322 = storage_alloc(size344);
	number_t macroDef339;env_t_341 env_t_341_value = make_empty_env(); closure_t closure332 = make_closure(lambda341, &env_t_341_value);
	env_t_342 env_t_342_value = make_empty_env(); closure_t closure335 = make_closure(lambda342, &env_t_342_value);
	env_t_343 env_t_343_value = make_empty_env(); closure_t closure338 = make_closure(lambda343, &env_t_343_value);
	macroDef339 = TOP_LEVEL_linalg_vectorSum_dps(stgVar321, TOP_LEVEL_linalg_vectorMap2_dps(stgVar322, closure332, x_dps, y_dps, closure335, x_shp, y_shp), TOP_LEVEL_linalg_vectorMap2_shp(closure338, x_shp, y_shp));;
	storage_free(stgVar322, size344);
	return macroDef339;
}
typedef struct env_t_355 {
	card_t row_shp;
} env_t_355;
env_t_355 make_env_t_355(card_t row_shp) {
	env_t_355 env;
	env.row_shp = row_shp;
	return env;
}

value_t lambda355(env_t_355* env352, card_t r_shp) {
	card_t row_shp351 = env352->row_shp;
	value_t res;
	res.card_t_value = row_shp351;
	return res;
}
matrix_shape_t TOP_LEVEL_linalg_matrixFillFromVector_shp(card_t rows_shp, card_t row_shp) {
	env_t_355 env_t_355_value = make_env_t_355(row_shp); closure_t closure354 = make_closure(lambda355, &env_t_355_value);
	return TOP_LEVEL_linalg_vectorMapToMatrix_shp(closure354, TOP_LEVEL_linalg_vectorRange_shp(1, rows_shp));
}

typedef struct env_t_365 {
	array_number_t row_dps;
} env_t_365;
env_t_365 make_env_t_365(array_number_t row_dps) {
	env_t_365 env;
	env.row_dps = row_dps;
	return env;
}

value_t lambda365(env_t_365* env357, storage_t stgVar348, number_t r_dps, card_t r_shp) {
	array_number_t row_dps356 = env357->row_dps;
	value_t res;
	res.array_number_t_value = row_dps356;
	return res;
}
typedef struct env_t_366 {
	card_t row_shp;
} env_t_366;
env_t_366 make_env_t_366(card_t row_shp) {
	env_t_366 env;
	env.row_shp = row_shp;
	return env;
}

value_t lambda366(env_t_366* env361, card_t r_shp) {
	card_t row_shp360 = env361->row_shp;
	value_t res;
	res.card_t_value = row_shp360;
	return res;
}
array_array_number_t TOP_LEVEL_linalg_matrixFillFromVector_dps(storage_t stgVar345, card_t rows_dps, array_number_t row_dps, card_t rows_shp, card_t row_shp) {
	card_t size367 = width_card_t(TOP_LEVEL_linalg_vectorRange_shp(1, rows_shp));
	array_number_t stgVar347 = storage_alloc(size367);
	array_array_number_t macroDef364;env_t_365 env_t_365_value = make_env_t_365(row_dps); closure_t closure359 = make_closure(lambda365, &env_t_365_value);
	env_t_366 env_t_366_value = make_env_t_366(row_shp); closure_t closure363 = make_closure(lambda366, &env_t_366_value);
	macroDef364 = TOP_LEVEL_linalg_vectorMapToMatrix_dps(stgVar345, closure359, TOP_LEVEL_linalg_vectorRange_dps(stgVar347, 1, rows_dps, 1, rows_shp), closure363, TOP_LEVEL_linalg_vectorRange_shp(1, rows_shp));;
	storage_free(stgVar347, size367);
	return macroDef364;
}

matrix_shape_t TOP_LEVEL_linalg_matrixFill_shp(card_t rows_shp, card_t cols_shp, card_t value_shp) {
	
	return nested_shape_card_t(cols_shp, rows_shp);
}


array_array_number_t TOP_LEVEL_linalg_matrixFill_dps(storage_t stgVar368, card_t rows_dps, card_t cols_dps, number_t value_dps, card_t rows_shp, card_t cols_shp, card_t value_shp) {
	array_array_number_t macroDef372 = (array_array_number_t)stgVar368;
		macroDef372->length=rows_dps;
		macroDef372->arr=(array_number_t*)(STG_OFFSET(macroDef372, VECTOR_HEADER_BYTES));
		storage_t stgVar369 = (STG_OFFSET(macroDef372, MATRIX_HEADER_BYTES(rows_dps)));
		for(int r_dps = 0; r_dps < macroDef372->length; r_dps++){
			array_number_t macroDef371 = (array_number_t)stgVar369;
		macroDef371->length=cols_dps;
		macroDef371->arr=(number_t*)(STG_OFFSET(macroDef371, VECTOR_HEADER_BYTES));
		storage_t stgVar370 = macroDef371;
		for(int c_dps = 0; c_dps < macroDef371->length; c_dps++){
			
			macroDef371->arr[c_dps] = value_dps;;
			stgVar370 = STG_OFFSET(stgVar370, sizeof(number_t));
		}
			macroDef372->arr[r_dps] = macroDef371;;
			stgVar369 = STG_OFFSET(stgVar369, VECTOR_ALL_BYTES(macroDef372->arr[r_dps]->length));
		}
	return macroDef372;
}

matrix_shape_t TOP_LEVEL_linalg_matrixTranspose_shp(matrix_shape_t m_shp) {
	
	return nested_shape_card_t(m_shp.card, m_shp.elem);
}


array_array_number_t TOP_LEVEL_linalg_matrixTranspose_dps(storage_t stgVar373, array_array_number_t m_dps, matrix_shape_t m_shp) {
	card_t rows_shp = m_shp.card;
	card_t macroDef385 = m_dps->length;
	card_t rows_dps = macroDef385;
	card_t cols_shp = m_shp.elem;
	card_t size391 = width_card_t(m_shp.elem);
	array_number_t stgVar377 = storage_alloc(size391);
	card_t macroDef387;card_t macroDef386 = m_dps->arr[0]->length;
	macroDef387 = macroDef386;;
	storage_free(stgVar377, size391);
	card_t cols_dps = macroDef387;
	array_array_number_t macroDef390 = (array_array_number_t)stgVar373;
		macroDef390->length=cols_dps;
		macroDef390->arr=(array_number_t*)(STG_OFFSET(macroDef390, VECTOR_HEADER_BYTES));
		storage_t stgVar379 = (STG_OFFSET(macroDef390, MATRIX_HEADER_BYTES(cols_dps)));
		for(int i_dps = 0; i_dps < macroDef390->length; i_dps++){
			array_number_t macroDef389 = (array_number_t)stgVar379;
		macroDef389->length=rows_dps;
		macroDef389->arr=(number_t*)(STG_OFFSET(macroDef389, VECTOR_HEADER_BYTES));
		storage_t stgVar380 = macroDef389;
		for(int j_dps = 0; j_dps < macroDef389->length; j_dps++){
			card_t size392 = width_card_t(m_shp.elem);
	array_number_t stgVar381 = storage_alloc(size392);
	number_t macroDef388;
	macroDef388 = m_dps->arr[j_dps]->arr[i_dps];;
	storage_free(stgVar381, size392);
			macroDef389->arr[j_dps] = macroDef388;;
			stgVar380 = STG_OFFSET(stgVar380, sizeof(number_t));
		}
			macroDef390->arr[i_dps] = macroDef389;;
			stgVar379 = STG_OFFSET(stgVar379, VECTOR_ALL_BYTES(macroDef390->arr[i_dps]->length));
		}
	return macroDef390;
}

matrix_shape_t TOP_LEVEL_linalg_matrixMult_shp(matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	
	return nested_shape_card_t(m2_shp.elem, m1_shp.card);
}


array_array_number_t TOP_LEVEL_linalg_matrixMult_dps(storage_t stgVar393, array_array_number_t m1_dps, array_array_number_t m2_dps, matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	card_t r1_shp = m1_shp.card;
	card_t macroDef432 = m1_dps->length;
	card_t r1_dps = macroDef432;
	card_t c2_shp = m2_shp.elem;
	card_t size443 = width_card_t(m2_shp.elem);
	array_number_t stgVar397 = storage_alloc(size443);
	card_t macroDef434;card_t macroDef433 = m2_dps->arr[0]->length;
	macroDef434 = macroDef433;;
	storage_free(stgVar397, size443);
	card_t c2_dps = macroDef434;
	card_t c1_shp = m1_shp.elem;
	card_t size444 = width_card_t(m1_shp.elem);
	array_number_t stgVar400 = storage_alloc(size444);
	card_t macroDef436;card_t macroDef435 = m1_dps->arr[0]->length;
	macroDef436 = macroDef435;;
	storage_free(stgVar400, size444);
	card_t c1_dps = macroDef436;
	card_t r2_shp = m2_shp.card;
	card_t macroDef437 = m2_dps->length;
	card_t r2_dps = macroDef437;
	matrix_shape_t m2T_shp = TOP_LEVEL_linalg_matrixTranspose_shp(m2_shp);
	card_t size447 = width_matrix_shape_t(m2T_shp);
	array_number_t stgVar404 = storage_alloc(size447);
	array_array_number_t macroDef442;array_array_number_t m2T_dps = TOP_LEVEL_linalg_matrixTranspose_dps(stgVar404, m2_dps, m2_shp);
	array_array_number_t macroDef441 = (array_array_number_t)stgVar393;
		macroDef441->length=r1_dps;
		macroDef441->arr=(array_number_t*)(STG_OFFSET(macroDef441, VECTOR_HEADER_BYTES));
		storage_t stgVar406 = (STG_OFFSET(macroDef441, MATRIX_HEADER_BYTES(r1_dps)));
		for(int r_dps = 0; r_dps < macroDef441->length; r_dps++){
			array_number_t macroDef440 = (array_number_t)stgVar406;
		macroDef440->length=c2_dps;
		macroDef440->arr=(number_t*)(STG_OFFSET(macroDef440, VECTOR_HEADER_BYTES));
		storage_t stgVar407 = macroDef440;
		for(int c_dps = 0; c_dps < macroDef440->length; c_dps++){
			card_t size446 = width_card_t(m2T_shp.elem);
	array_number_t stgVar409 = storage_alloc(size446);
	number_t macroDef439;card_t size445 = width_card_t(m1_shp.elem);
	array_number_t stgVar408 = storage_alloc(size445);
	number_t macroDef438;
	macroDef438 = TOP_LEVEL_linalg_dot_prod_dps(stgVar407, m1_dps->arr[r_dps], m2T_dps->arr[c_dps], m1_shp.elem, m2T_shp.elem);;
	storage_free(stgVar408, size445);
	macroDef439 = macroDef438;;
	storage_free(stgVar409, size446);
			macroDef440->arr[c_dps] = macroDef439;;
			stgVar407 = STG_OFFSET(stgVar407, sizeof(number_t));
		}
			macroDef441->arr[r_dps] = macroDef440;;
			stgVar406 = STG_OFFSET(stgVar406, VECTOR_ALL_BYTES(macroDef441->arr[r_dps]->length));
		}
	macroDef442 = macroDef441;;
	storage_free(stgVar404, size447);
	return macroDef442;
}

card_t TOP_LEVEL_linalg_matrixVectorMult_shp(matrix_shape_t m_shp, card_t v_shp) {
	
	return TOP_LEVEL_linalg_rows_shp(m_shp);
}


array_number_t TOP_LEVEL_linalg_matrixVectorMult_dps(storage_t stgVar448, array_array_number_t m_dps, array_number_t v_dps, matrix_shape_t m_shp, card_t v_shp) {
	card_t r_shp = TOP_LEVEL_linalg_rows_shp(m_shp);
	card_t size465 = width_card_t(r_shp);
	array_number_t stgVar449 = storage_alloc(size465);
	array_number_t macroDef462;card_t r_dps = TOP_LEVEL_linalg_rows_dps(stgVar449, m_dps, m_shp);
	card_t c_shp = TOP_LEVEL_linalg_cols_shp(m_shp);
	card_t size464 = width_card_t(c_shp);
	array_number_t stgVar451 = storage_alloc(size464);
	array_number_t macroDef461;card_t c_dps = TOP_LEVEL_linalg_cols_dps(stgVar451, m_dps, m_shp);
	array_number_t macroDef460 = (array_number_t)stgVar448;
		macroDef460->length=r_dps;
		macroDef460->arr=(number_t*)(STG_OFFSET(macroDef460, VECTOR_HEADER_BYTES));
		storage_t stgVar453 = macroDef460;
		for(int i_dps = 0; i_dps < macroDef460->length; i_dps++){
			card_t size463 = width_card_t(m_shp.elem);
	array_number_t stgVar454 = storage_alloc(size463);
	number_t macroDef459;
	macroDef459 = TOP_LEVEL_linalg_dot_prod_dps(stgVar453, m_dps->arr[i_dps], v_dps, m_shp.elem, v_shp);;
	storage_free(stgVar454, size463);
			macroDef460->arr[i_dps] = macroDef459;;
			stgVar453 = STG_OFFSET(stgVar453, sizeof(number_t));
		}
	macroDef461 = macroDef460;;
	storage_free(stgVar451, size464);
	macroDef462 = macroDef461;;
	storage_free(stgVar449, size465);
	return macroDef462;
}

matrix_shape_t TOP_LEVEL_linalg_matrixConcat_shp(matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	
	return nested_shape_card_t(m1_shp.elem, (m1_shp.card) + (m2_shp.card));
}


array_array_number_t TOP_LEVEL_linalg_matrixConcat_dps(storage_t stgVar466, array_array_number_t m1_dps, array_array_number_t m2_dps, matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	card_t rows_shp = (m1_shp.card) + (m2_shp.card);
	card_t macroDef477 = m1_dps->length;
	card_t macroDef478 = m2_dps->length;
	card_t rows_dps = (macroDef477) + (macroDef478);
	card_t m1Rows_shp = 0;
	card_t macroDef479 = m1_dps->length;
	index_t m1Rows_dps = (macroDef479);
	array_array_number_t macroDef480 = (array_array_number_t)stgVar466;
		macroDef480->length=rows_dps;
		macroDef480->arr=(array_number_t*)(STG_OFFSET(macroDef480, VECTOR_HEADER_BYTES));
		storage_t stgVar472 = (STG_OFFSET(macroDef480, MATRIX_HEADER_BYTES(rows_dps)));
		for(int r_dps = 0; r_dps < macroDef480->length; r_dps++){
			array_number_t ite481 = 0;
	if((r_dps) < (m1Rows_dps)) {
		
		ite481 = m1_dps->arr[r_dps];;
	} else {
		
		ite481 = m2_dps->arr[(r_dps) - (m1Rows_dps)];;
	}
			macroDef480->arr[r_dps] = ite481;;
			stgVar472 = STG_OFFSET(stgVar472, VECTOR_ALL_BYTES(macroDef480->arr[r_dps]->length));
		}
	return macroDef480;
}

matrix_shape_t TOP_LEVEL_linalg_matrixConcatCol_shp(matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	
	return TOP_LEVEL_linalg_matrixTranspose_shp(TOP_LEVEL_linalg_matrixConcat_shp(TOP_LEVEL_linalg_matrixTranspose_shp(m1_shp), TOP_LEVEL_linalg_matrixTranspose_shp(m2_shp)));
}


array_array_number_t TOP_LEVEL_linalg_matrixConcatCol_dps(storage_t stgVar482, array_array_number_t m1_dps, array_array_number_t m2_dps, matrix_shape_t m1_shp, matrix_shape_t m2_shp) {
	matrix_shape_t m1t_shp = TOP_LEVEL_linalg_matrixTranspose_shp(m1_shp);
	card_t size497 = width_matrix_shape_t(m1t_shp);
	array_number_t stgVar483 = storage_alloc(size497);
	array_array_number_t macroDef494;array_array_number_t m1t_dps = TOP_LEVEL_linalg_matrixTranspose_dps(stgVar483, m1_dps, m1_shp);
	matrix_shape_t m2t_shp = TOP_LEVEL_linalg_matrixTranspose_shp(m2_shp);
	card_t size496 = width_matrix_shape_t(m2t_shp);
	array_number_t stgVar485 = storage_alloc(size496);
	array_array_number_t macroDef493;array_array_number_t m2t_dps = TOP_LEVEL_linalg_matrixTranspose_dps(stgVar485, m2_dps, m2_shp);
	card_t size495 = width_matrix_shape_t(TOP_LEVEL_linalg_matrixConcat_shp(m1t_shp, m2t_shp));
	array_number_t stgVar487 = storage_alloc(size495);
	array_array_number_t macroDef492;
	macroDef492 = TOP_LEVEL_linalg_matrixTranspose_dps(stgVar482, TOP_LEVEL_linalg_matrixConcat_dps(stgVar487, m1t_dps, m2t_dps, m1t_shp, m2t_shp), TOP_LEVEL_linalg_matrixConcat_shp(m1t_shp, m2t_shp));;
	storage_free(stgVar487, size495);
	macroDef493 = macroDef492;;
	storage_free(stgVar485, size496);
	macroDef494 = macroDef493;;
	storage_free(stgVar483, size497);
	return macroDef494;
}

matrix3d_shape_t TOP_LEVEL_linalg_matrix3DConcat_shp(matrix3d_shape_t m1_shp, matrix3d_shape_t m2_shp) {
	
	return nested_shape_matrix_shape_t(m1_shp.elem, (m1_shp.card) + (m2_shp.card));
}


array_array_array_number_t TOP_LEVEL_linalg_matrix3DConcat_dps(storage_t stgVar498, array_array_array_number_t m1_dps, array_array_array_number_t m2_dps, matrix3d_shape_t m1_shp, matrix3d_shape_t m2_shp) {
	card_t rows_shp = (m1_shp.card) + (m2_shp.card);
	card_t macroDef509 = m1_dps->length;
	card_t macroDef510 = m2_dps->length;
	card_t rows_dps = (macroDef509) + (macroDef510);
	card_t m1Rows_shp = 0;
	card_t macroDef511 = m1_dps->length;
	index_t m1Rows_dps = (macroDef511);
	array_array_array_number_t macroDef512 = (array_array_array_number_t)stgVar498;
		macroDef512->length=rows_dps;
		macroDef512->arr=(array_array_number_t*)(STG_OFFSET(macroDef512, VECTOR_HEADER_BYTES));
		storage_t stgVar504 = (STG_OFFSET(macroDef512, MATRIX_HEADER_BYTES(rows_dps)));
		for(int r_dps = 0; r_dps < macroDef512->length; r_dps++){
			array_array_number_t ite513 = 0;
	if((r_dps) < (m1Rows_dps)) {
		
		ite513 = m1_dps->arr[r_dps];;
	} else {
		
		ite513 = m2_dps->arr[(r_dps) - (m1Rows_dps)];;
	}
			macroDef512->arr[r_dps] = ite513;;
			stgVar504 = STG_OFFSET(stgVar504, VECTOR_ALL_BYTES(macroDef512->arr[r_dps]->length));
		}
	return macroDef512;
}

card_t TOP_LEVEL_linalg_vectorRead_shp(card_t fn_shp, card_t startLine_shp, card_t cols_shp) {
	
	return nested_shape_card_t(cols_shp, 1).elem;
}


array_number_t TOP_LEVEL_linalg_vectorRead_dps(storage_t stgVar514, string_t fn_dps, index_t startLine_dps, card_t cols_dps, card_t fn_shp, card_t startLine_shp, card_t cols_shp) {
	matrix_shape_t matrix_shp = nested_shape_card_t(cols_shp, 1);
	card_t size518 = width_matrix_shape_t(matrix_shp);
	array_number_t stgVar515 = storage_alloc(size518);
	array_number_t macroDef517;array_array_number_t matrix_dps = matrix_read_s(stgVar515, fn_dps, startLine_dps, 1, cols_dps);
	macroDef517 = matrix_dps->arr[0];;
	storage_free(stgVar515, size518);
	return macroDef517;
}

card_t TOP_LEVEL_linalg_numberRead_shp(card_t fn_shp, card_t startLine_shp) {
	
	return 0;
}


number_t TOP_LEVEL_linalg_numberRead_dps(storage_t stgVar519, string_t fn_dps, index_t startLine_dps, card_t fn_shp, card_t startLine_shp) {
	card_t vector_shp = TOP_LEVEL_linalg_vectorRead_shp(0, 0, 1);
	card_t size526 = width_card_t(vector_shp);
	array_number_t stgVar520 = storage_alloc(size526);
	number_t macroDef525;array_number_t vector_dps = TOP_LEVEL_linalg_vectorRead_dps(stgVar520, fn_dps, startLine_dps, 1, 0, 0, 1);
	macroDef525 = vector_dps->arr[0];;
	storage_free(stgVar520, size526);
	return macroDef525;
}

card_t TOP_LEVEL_linalg_vec3_shp(card_t a_shp, card_t b_shp, card_t c_shp) {
	
	return 3;
}


array_number_t TOP_LEVEL_linalg_vec3_dps(storage_t stgVar527, number_t a_dps, number_t b_dps, number_t c_dps, card_t a_shp, card_t b_shp, card_t c_shp) {
	array_number_t macroDef531 = (array_number_t)stgVar527;
	macroDef531->length=3;
	macroDef531->arr=(number_t*)(STG_OFFSET(stgVar527, VECTOR_HEADER_BYTES));
	

	macroDef531->arr[0] = a_dps;;

	macroDef531->arr[1] = b_dps;;

	macroDef531->arr[2] = c_dps;;;
	return macroDef531;
}
#endif
