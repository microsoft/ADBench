#ifndef __USECASES_GMM_STORAGED_H__ 
#define __USECASES_GMM_STORAGED_H__ 
#include "fsharp.h"
#include <stdio.h>
#include <math.h>
#include "linalg_storaged.h"

card_t TOP_LEVEL_usecases_gmm_logsumexp_shp(card_t arr_shp) {
	
	return 0;
}

typedef empty_env_t env_t_1250;


value_t lambda1250(env_t_1250* env1236, card_t x_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef struct env_t_1251 {
	number_t mx_dps;
} env_t_1251;
env_t_1251 make_env_t_1251(number_t mx_dps) {
	env_t_1251 env;
	env.mx_dps = mx_dps;
	return env;
}

value_t lambda1251(env_t_1251* env1240, storage_t stgVar1235, number_t x_dps, card_t x_shp) {
	number_t mx_dps1239 = env1240->mx_dps;
	value_t res;
	res.number_t_value = exp((x_dps) - (mx_dps1239));
	return res;
}
typedef empty_env_t env_t_1252;


value_t lambda1252(env_t_1252* env1243, card_t x_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_1253;


value_t lambda1253(env_t_1253* env1246, card_t x_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_usecases_gmm_logsumexp_dps(storage_t stgVar1228, array_number_t arr_dps, card_t arr_shp) {
	card_t mx_shp = 0;
	number_t mx_dps = TOP_LEVEL_linalg_vectorMax_dps(empty_storage, arr_dps, arr_shp);
	card_t semx_shp = 0;
	env_t_1250 env_t_1250_value = make_empty_env(); closure_t closure1238 = make_closure(lambda1250, &env_t_1250_value);
	card_t size1254 = width_card_t(TOP_LEVEL_linalg_vectorMap_shp(closure1238, arr_shp));
	array_number_t stgVar1232 = storage_alloc(size1254);
	number_t macroDef1249;env_t_1251 env_t_1251_value = make_env_t_1251(mx_dps); closure_t closure1242 = make_closure(lambda1251, &env_t_1251_value);
	env_t_1252 env_t_1252_value = make_empty_env(); closure_t closure1245 = make_closure(lambda1252, &env_t_1252_value);
	env_t_1253 env_t_1253_value = make_empty_env(); closure_t closure1248 = make_closure(lambda1253, &env_t_1253_value);
	macroDef1249 = TOP_LEVEL_linalg_vectorSum_dps(empty_storage, TOP_LEVEL_linalg_vectorMap_dps(stgVar1232, closure1242, arr_dps, closure1245, arr_shp), TOP_LEVEL_linalg_vectorMap_shp(closure1248, arr_shp));;
	storage_free(stgVar1232, size1254);
	number_t semx_dps = macroDef1249;
	return (log(semx_dps)) + (mx_dps);
}

card_t TOP_LEVEL_usecases_gmm_tri_shp(card_t n_shp) {
	
	return 0;
}


index_t TOP_LEVEL_usecases_gmm_tri_dps(storage_t stgVar1255, index_t n_dps, card_t n_shp) {
	
	return ((n_dps) * ((n_dps) + (1))) / (2);
}

card_t TOP_LEVEL_usecases_gmm_Qtimesv_shp(card_t q_shp, card_t l_shp, card_t v_shp) {
	
	return v_shp;
}


array_number_t TOP_LEVEL_usecases_gmm_Qtimesv_dps(storage_t stgVar1256, array_number_t q_dps, array_number_t l_dps, array_number_t v_dps, card_t q_shp, card_t l_shp, card_t v_shp) {
	card_t macroDef1274 = v_dps->length;
	array_number_t macroDef1277 = (array_number_t)stgVar1256;
		macroDef1277->length=macroDef1274;
		macroDef1277->arr=(number_t*)(STG_OFFSET(macroDef1277, VECTOR_HEADER_BYTES));
		storage_t stgVar1258 = macroDef1277;
		for(int i_dps = 0; i_dps < macroDef1277->length; i_dps++){
			card_t tis_shp = 0;
			index_t tis_dps = TOP_LEVEL_usecases_gmm_tri_dps(empty_storage, (i_dps) - (1), 0);
			card_t sum_shp = 0;
			card_t anfvar1262_shp = l_shp;
			card_t macroDef1275 = l_dps->length;
			card_t anfvar1262_dps = macroDef1275;
			card_t anfvar1263_shp = 0;
			card_t anfvar1263_dps = 0;
			number_t macroDef1276 = 0;
	storage_t stgVar1267 = empty_storage;
	for(int idx_dps = anfvar1263_dps; idx_dps <= anfvar1262_dps; idx_dps++){
		card_t j_shp = 0;
		index_t j_dps = (idx_dps) - (tis_dps);
		card_t isInRange_shp = 0;
		bool_t isInRange_dps = 0;
	if((j_dps) >= (0)) {
		
		isInRange_dps = (j_dps) < (i_dps);;
	} else {
		
		isInRange_dps = false;;
	}
		number_t ite1278 = 0;
	if(isInRange_dps) {
		
		ite1278 = (macroDef1276) + ((l_dps->arr[idx_dps]) * (v_dps->arr[j_dps]));;
	} else {
		
		ite1278 = macroDef1276;;
	}
		macroDef1276 = ite1278;;
	}
			number_t sum_dps = macroDef1276;
			macroDef1277->arr[i_dps] = (sum_dps) + ((exp(q_dps->arr[i_dps])) * (v_dps->arr[i_dps]));;
			stgVar1258 = STG_OFFSET(stgVar1258, sizeof(number_t));
		}
	return macroDef1277;
}

card_t TOP_LEVEL_usecases_gmm_Qtimesv_test_shp(card_t unitVar0_shp) {
	
	return 0;
}


void TOP_LEVEL_usecases_gmm_Qtimesv_test_dps(storage_t stgVar1279, int unitVar0_dps, card_t unitVar0_shp) {
	card_t q_shp = TOP_LEVEL_linalg_vec3_shp(0, 0, 0);
	card_t size1330 = width_card_t(q_shp);
	array_number_t stgVar1280 = storage_alloc(size1330);
	array_number_t q_dps = TOP_LEVEL_linalg_vec3_dps(stgVar1280, 0.1, -1, 0.3, 0, 0, 0);
	card_t l_shp = TOP_LEVEL_linalg_vec3_shp(0, 0, 0);
	card_t size1329 = width_card_t(l_shp);
	array_number_t stgVar1284 = storage_alloc(size1329);
	array_number_t l_dps = TOP_LEVEL_linalg_vec3_dps(stgVar1284, 5, -2, 7.1, 0, 0, 0);
	card_t v_shp = TOP_LEVEL_linalg_vec3_shp(0, 0, 0);
	card_t size1328 = width_card_t(v_shp);
	array_number_t stgVar1288 = storage_alloc(size1328);
	array_number_t v_dps = TOP_LEVEL_linalg_vec3_dps(stgVar1288, 1.4, -7, 3.1, 0, 0, 0);
	card_t ans0_shp = 0;
	number_t ans0_dps = (exp(q_dps->arr[0])) * (v_dps->arr[0]);
	card_t ans1_shp = 0;
	number_t ans1_dps = ((l_dps->arr[0]) * (v_dps->arr[0])) + ((exp(q_dps->arr[1])) * (v_dps->arr[1]));
	card_t ans2_shp = 0;
	number_t ans2_dps = (((l_dps->arr[1]) * (v_dps->arr[0])) + ((l_dps->arr[2]) * (v_dps->arr[1]))) + ((exp(q_dps->arr[2])) * (v_dps->arr[2]));
	card_t ans_shp = TOP_LEVEL_linalg_vec3_shp(0, 0, 0);
	card_t size1327 = width_card_t(ans_shp);
	array_number_t stgVar1307 = storage_alloc(size1327);
	array_number_t ans_dps = TOP_LEVEL_linalg_vec3_dps(stgVar1307, ans0_dps, ans1_dps, ans2_dps, 0, 0, 0);
	card_t qv_shp = TOP_LEVEL_usecases_gmm_Qtimesv_shp(q_shp, l_shp, v_shp);
	card_t size1326 = width_card_t(qv_shp);
	array_number_t stgVar1311 = storage_alloc(size1326);
	array_number_t qv_dps = TOP_LEVEL_usecases_gmm_Qtimesv_dps(stgVar1311, q_dps, l_dps, v_dps, q_shp, l_shp, v_shp);
	card_t nrm_shp = 0;
	card_t size1325 = width_card_t(TOP_LEVEL_linalg_vectorSub_shp(qv_shp, ans_shp));
	array_number_t stgVar1316 = storage_alloc(size1325);
	number_t macroDef1319;
	macroDef1319 = TOP_LEVEL_linalg_sqnorm_dps(empty_storage, TOP_LEVEL_linalg_vectorSub_dps(stgVar1316, qv_dps, ans_dps, qv_shp, ans_shp), TOP_LEVEL_linalg_vectorSub_shp(qv_shp, ans_shp));;
	storage_free(stgVar1316, size1325);
	number_t nrm_dps = macroDef1319;
	number_print(nrm_dps);
	storage_free(stgVar1311, size1326);
	;
	storage_free(stgVar1307, size1327);
	;
	storage_free(stgVar1288, size1328);
	;
	storage_free(stgVar1284, size1329);
	;
	storage_free(stgVar1280, size1330);
	return ;
}

card_t TOP_LEVEL_usecases_gmm_gmm_objective_shp(matrix_shape_t x_shp, card_t alphas_shp, matrix_shape_t means_shp, matrix_shape_t qs_shp, matrix_shape_t ls_shp, card_t wishart_gamma_shp, card_t wishart_m_shp) {
	
	return 0;
}

typedef empty_env_t env_t_1405;


value_t lambda1405(env_t_1405* env1377, card_t value_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_1406;


value_t lambda1406(env_t_1406* env1380, storage_t stgVar1361, number_t value_dps, card_t value_shp) {
	
	value_t res;
	res.number_t_value = exp(value_dps);
	return res;
}
typedef empty_env_t env_t_1407;


value_t lambda1407(env_t_1407* env1383, card_t value_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
typedef empty_env_t env_t_1409;


value_t lambda1409(env_t_1409* env1387, card_t value_shp) {
	
	value_t res;
	res.card_t_value = 0;
	return res;
}
number_t TOP_LEVEL_usecases_gmm_gmm_objective_dps(storage_t stgVar1331, array_array_number_t x_dps, array_number_t alphas_dps, array_array_number_t means_dps, array_array_number_t qs_dps, array_array_number_t ls_dps, number_t wishart_gamma_dps, number_t wishart_m_dps, matrix_shape_t x_shp, card_t alphas_shp, matrix_shape_t means_shp, matrix_shape_t qs_shp, matrix_shape_t ls_shp, card_t wishart_gamma_shp, card_t wishart_m_shp) {
	card_t n_shp = TOP_LEVEL_linalg_rows_shp(x_shp);
	card_t size1414 = width_card_t(n_shp);
	array_number_t stgVar1332 = storage_alloc(size1414);
	number_t macroDef1395;card_t n_dps = TOP_LEVEL_linalg_rows_dps(stgVar1332, x_dps, x_shp);
	card_t d_shp = TOP_LEVEL_linalg_cols_shp(x_shp);
	card_t size1413 = width_card_t(d_shp);
	array_number_t stgVar1334 = storage_alloc(size1413);
	number_t macroDef1394;card_t d_dps = TOP_LEVEL_linalg_cols_dps(stgVar1334, x_dps, x_shp);
	card_t K_shp = alphas_shp;
	card_t macroDef1365 = alphas_dps->length;
	card_t K_dps = macroDef1365;
	card_t size1404 = width_card_t(n_shp);
	array_number_t stgVar1338 = storage_alloc(size1404);
	number_t macroDef1376;array_number_t macroDef1375 = (array_number_t)stgVar1338;
		macroDef1375->length=n_dps;
		macroDef1375->arr=(number_t*)(STG_OFFSET(macroDef1375, VECTOR_HEADER_BYTES));
		storage_t stgVar1339 = macroDef1375;
		for(int i_dps = 0; i_dps < macroDef1375->length; i_dps++){
			card_t size1403 = width_card_t(K_shp);
	array_number_t stgVar1340 = storage_alloc(size1403);
	number_t macroDef1374;array_number_t macroDef1373 = (array_number_t)stgVar1340;
		macroDef1373->length=K_dps;
		macroDef1373->arr=(number_t*)(STG_OFFSET(macroDef1373, VECTOR_HEADER_BYTES));
		storage_t stgVar1341 = macroDef1373;
		for(int k_dps = 0; k_dps < macroDef1373->length; k_dps++){
			card_t size1396 = width_card_t(qs_shp.elem);
	array_number_t stgVar1343 = storage_alloc(size1396);
	number_t macroDef1366;
	macroDef1366 = TOP_LEVEL_linalg_vectorSum_dps(empty_storage, qs_dps->arr[k_dps], qs_shp.elem);;
	storage_free(stgVar1343, size1396);
			card_t size1402 = width_card_t(TOP_LEVEL_usecases_gmm_Qtimesv_shp(qs_shp.elem, ls_shp.elem, TOP_LEVEL_linalg_vectorSub_shp(x_shp.elem, means_shp.elem)));
	array_number_t stgVar1345 = storage_alloc(size1402);
	number_t macroDef1372;card_t size1401 = width_card_t(TOP_LEVEL_linalg_vectorSub_shp(x_shp.elem, means_shp.elem));
	array_number_t stgVar1348 = storage_alloc(size1401);
	array_number_t macroDef1371;card_t size1400 = width_card_t(ls_shp.elem);
	array_number_t stgVar1347 = storage_alloc(size1400);
	array_number_t macroDef1370;card_t size1399 = width_card_t(qs_shp.elem);
	array_number_t stgVar1346 = storage_alloc(size1399);
	array_number_t macroDef1369;card_t size1398 = width_card_t(means_shp.elem);
	array_number_t stgVar1352 = storage_alloc(size1398);
	array_number_t macroDef1368;card_t size1397 = width_card_t(x_shp.elem);
	array_number_t stgVar1351 = storage_alloc(size1397);
	array_number_t macroDef1367;
	macroDef1367 = TOP_LEVEL_linalg_vectorSub_dps(stgVar1348, x_dps->arr[i_dps], means_dps->arr[k_dps], x_shp.elem, means_shp.elem);;
	storage_free(stgVar1351, size1397);
	macroDef1368 = macroDef1367;;
	storage_free(stgVar1352, size1398);
	macroDef1369 = TOP_LEVEL_usecases_gmm_Qtimesv_dps(stgVar1345, qs_dps->arr[k_dps], ls_dps->arr[k_dps], macroDef1368, qs_shp.elem, ls_shp.elem, TOP_LEVEL_linalg_vectorSub_shp(x_shp.elem, means_shp.elem));;
	storage_free(stgVar1346, size1399);
	macroDef1370 = macroDef1369;;
	storage_free(stgVar1347, size1400);
	macroDef1371 = macroDef1370;;
	storage_free(stgVar1348, size1401);
	macroDef1372 = TOP_LEVEL_linalg_sqnorm_dps(empty_storage, macroDef1371, TOP_LEVEL_usecases_gmm_Qtimesv_shp(qs_shp.elem, ls_shp.elem, TOP_LEVEL_linalg_vectorSub_shp(x_shp.elem, means_shp.elem)));;
	storage_free(stgVar1345, size1402);
			macroDef1373->arr[k_dps] = ((alphas_dps->arr[k_dps]) + (macroDef1366)) - ((0.5) * (macroDef1372));;
			stgVar1341 = STG_OFFSET(stgVar1341, sizeof(number_t));
		}
	macroDef1374 = TOP_LEVEL_usecases_gmm_logsumexp_dps(stgVar1339, macroDef1373, K_shp);;
	storage_free(stgVar1340, size1403);
			macroDef1375->arr[i_dps] = macroDef1374;;
			stgVar1339 = STG_OFFSET(stgVar1339, sizeof(number_t));
		}
	macroDef1376 = TOP_LEVEL_linalg_vectorSum_dps(empty_storage, macroDef1375, n_shp);;
	storage_free(stgVar1338, size1404);
	card_t size1412 = width_card_t(K_shp);
	array_number_t stgVar1356 = storage_alloc(size1412);
	number_t macroDef1393;array_number_t macroDef1392 = (array_number_t)stgVar1356;
		macroDef1392->length=K_dps;
		macroDef1392->arr=(number_t*)(STG_OFFSET(macroDef1392, VECTOR_HEADER_BYTES));
		storage_t stgVar1357 = macroDef1392;
		for(int k_dps = 0; k_dps < macroDef1392->length; k_dps++){
			env_t_1405 env_t_1405_value = make_empty_env(); closure_t closure1379 = make_closure(lambda1405, &env_t_1405_value);
			card_t size1410 = width_card_t(TOP_LEVEL_linalg_vectorMap_shp(closure1379, qs_shp.elem));
	array_number_t stgVar1358 = storage_alloc(size1410);
	number_t macroDef1390;card_t size1408 = width_card_t(qs_shp.elem);
	array_number_t stgVar1360 = storage_alloc(size1408);
	array_number_t macroDef1386;env_t_1406 env_t_1406_value = make_empty_env(); closure_t closure1382 = make_closure(lambda1406, &env_t_1406_value);
	env_t_1407 env_t_1407_value = make_empty_env(); closure_t closure1385 = make_closure(lambda1407, &env_t_1407_value);
	macroDef1386 = TOP_LEVEL_linalg_vectorMap_dps(stgVar1358, closure1382, qs_dps->arr[k_dps], closure1385, qs_shp.elem);;
	storage_free(stgVar1360, size1408);
	env_t_1409 env_t_1409_value = make_empty_env(); closure_t closure1389 = make_closure(lambda1409, &env_t_1409_value);
	macroDef1390 = TOP_LEVEL_linalg_sqnorm_dps(empty_storage, macroDef1386, TOP_LEVEL_linalg_vectorMap_shp(closure1389, qs_shp.elem));;
	storage_free(stgVar1358, size1410);
			card_t size1411 = width_card_t(ls_shp.elem);
	array_number_t stgVar1363 = storage_alloc(size1411);
	number_t macroDef1391;
	macroDef1391 = TOP_LEVEL_linalg_sqnorm_dps(empty_storage, ls_dps->arr[k_dps], ls_shp.elem);;
	storage_free(stgVar1363, size1411);
			macroDef1392->arr[k_dps] = (macroDef1390) + (macroDef1391);;
			stgVar1357 = STG_OFFSET(stgVar1357, sizeof(number_t));
		}
	macroDef1393 = TOP_LEVEL_linalg_vectorSum_dps(empty_storage, macroDef1392, K_shp);;
	storage_free(stgVar1356, size1412);
	macroDef1394 = ((macroDef1376) - (((double)((n_dps))) * (TOP_LEVEL_usecases_gmm_logsumexp_dps(empty_storage, alphas_dps, alphas_shp)))) + ((0.5) * (macroDef1393));;
	storage_free(stgVar1334, size1413);
	macroDef1395 = macroDef1394;;
	storage_free(stgVar1332, size1414);
	return macroDef1395;
}

card_t TOP_LEVEL_usecases_gmm_test_gmm_shp(card_t dum_shp) {
	
	return 0;
}


void TOP_LEVEL_usecases_gmm_test_gmm_dps(storage_t stgVar1415, array_number_t dum_dps, card_t dum_shp) {
	card_t a_shp = 3;
	card_t size1443 = width_card_t(a_shp);
	array_number_t stgVar1416 = storage_alloc(size1443);
	array_number_t macroDef1433 = (array_number_t)stgVar1416;
	macroDef1433->length=3;
	macroDef1433->arr=(number_t*)(STG_OFFSET(stgVar1416, VECTOR_HEADER_BYTES));
	

	macroDef1433->arr[0] = 1;;

	macroDef1433->arr[1] = 2;;

	macroDef1433->arr[2] = 3;;;
	array_number_t a_dps = macroDef1433;
	array_print(a_dps);
	matrix_shape_t mat1_shp = nested_shape_card_t(3, 3);
	card_t size1442 = width_matrix_shape_t(mat1_shp);
	array_number_t stgVar1420 = storage_alloc(size1442);
	array_array_number_t macroDef1437 = (array_array_number_t)stgVar1420;
	macroDef1437->length=3;
	macroDef1437->arr=(array_number_t*)(STG_OFFSET(stgVar1420, VECTOR_HEADER_BYTES));
	int stgVar1420_offsetVar = 0;storage_t stgVar1421 = STG_OFFSET(stgVar1420, MATRIX_HEADER_BYTES(3) + stgVar1420_offsetVar);array_number_t macroDef1434 = (array_number_t)stgVar1421;
	macroDef1434->length=3;
	macroDef1434->arr=(number_t*)(STG_OFFSET(stgVar1421, VECTOR_HEADER_BYTES));
	

	macroDef1434->arr[0] = 1;;

	macroDef1434->arr[1] = 2;;

	macroDef1434->arr[2] = 3;;;

	macroDef1437->arr[0] = macroDef1434;;stgVar1420_offsetVar += VECTOR_ALL_BYTES(macroDef1437->arr[0]->length);storage_t stgVar1425 = STG_OFFSET(stgVar1420, MATRIX_HEADER_BYTES(3) + stgVar1420_offsetVar);array_number_t macroDef1435 = (array_number_t)stgVar1425;
	macroDef1435->length=3;
	macroDef1435->arr=(number_t*)(STG_OFFSET(stgVar1425, VECTOR_HEADER_BYTES));
	

	macroDef1435->arr[0] = 4;;

	macroDef1435->arr[1] = 5;;

	macroDef1435->arr[2] = 6;;;

	macroDef1437->arr[1] = macroDef1435;;stgVar1420_offsetVar += VECTOR_ALL_BYTES(macroDef1437->arr[1]->length);storage_t stgVar1429 = STG_OFFSET(stgVar1420, MATRIX_HEADER_BYTES(3) + stgVar1420_offsetVar);array_number_t macroDef1436 = (array_number_t)stgVar1429;
	macroDef1436->length=3;
	macroDef1436->arr=(number_t*)(STG_OFFSET(stgVar1429, VECTOR_HEADER_BYTES));
	

	macroDef1436->arr[0] = 7;;

	macroDef1436->arr[1] = 8;;

	macroDef1436->arr[2] = 9;;;

	macroDef1437->arr[2] = macroDef1436;;stgVar1420_offsetVar += VECTOR_ALL_BYTES(macroDef1437->arr[2]->length);;
	array_array_number_t mat1_dps = macroDef1437;
	matrix_print(mat1_dps);
	;
	storage_free(stgVar1420, size1442);
	;
	storage_free(stgVar1416, size1443);
	return ;
}
#endif
