check_PROGRAMS = autodiff_benchmark animate
autodiff_benchmark_SOURCES = autodiff_benchmark.cpp advection_schemes_AD.cpp \
	advection_schemes_K.cpp differentiator.h advection_schemes.h \
	advection_schemes_AD.h advection_schemes_K.h nx.h
autodiff_benchmark_CPPFLAGS = -I../include
autodiff_benchmark_LDFLAGS = -static -no-install -L../adept/.libs
autodiff_benchmark_LDADD = -ladept

animate_SOURCES = animate.cpp
