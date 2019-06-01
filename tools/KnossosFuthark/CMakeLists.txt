cmake_minimum_required(VERSION 3.10)

project("Tools-KnossosFuthark")

add_executable("Tools-KnossosFuthark-GMM" "gmm.cpp" "gmm_wrapper.c" "gmm_wrapper.h" ${ARGN})
