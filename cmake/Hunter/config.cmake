#Ceres needs glog to be built with sharedlibs
hunter_config(glog
  VERSION ${HUNTER_glog_VERSION} CMAKE_ARGS
	BUILD_SHARED_LIBS=ON
)

# Making sure there will be GTest (when tests are enabled)
# in RelWithDebInfo configuration to link against
hunter_config(GTest 
	VERSION ${HUNTER_GTest_VERSION} 
	CONFIGURATION_TYPES Release RelWithDebInfo Debug 
	CMAKE_ARGS CMAKE_POSITION_INDEPENDENT_CODE=ON
)
