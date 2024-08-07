
######################
# ssl.ndll

add_library(ssl.ndll MODULE ssl.c)

if (STATIC_MBEDTLS)
	set(MBEDTLS_CMAKE_ARGS
		-Wno-dev
		-DENABLE_PROGRAMS=OFF
		-DENABLE_TESTING=OFF
		-DUSE_STATIC_MBEDTLS_LIBRARY=ON
		-DMBEDTLS_USER_CONFIG_FILE=${CMAKE_CURRENT_SOURCE_DIR}/mbedtls_config.h
	)
	if (UNIX)
		list(APPEND MBEDTLS_CMAKE_ARGS
			-DLINK_WITH_PTHREAD=ON
			-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
			-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
			${ARG_PIC}
		)
	endif()
	if (WIN32)
		set(MBEDTLS_LIBRARIES
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/${CMAKE_CFG_INTDIR}/mbedx509.lib
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/${CMAKE_CFG_INTDIR}/mbedtls.lib
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/${CMAKE_CFG_INTDIR}/mbedcrypto.lib
		)
		target_link_libraries(ssl.ndll ws2_32 Advapi32 Crypt32 bcrypt)
	else()
		set(MBEDTLS_LIBRARIES
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/libmbedx509.a
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/libmbedtls.a
			${CMAKE_BINARY_DIR}/libs/src/MbedTLS-build/library/libmbedcrypto.a
		)
	endif()
	ExternalProject_Add(MbedTLS
		${EP_CONFIGS}
		URL https://github.com/Mbed-TLS/mbedtls/releases/download/v3.6.0/mbedtls-3.6.0.tar.bz2
		URL_HASH SHA256=3ecf94fcfdaacafb757786a01b7538a61750ebd85c4b024f56ff8ba1490fcd38
		CMAKE_ARGS ${MBEDTLS_CMAKE_ARGS}
		PATCH_COMMAND ${CMAKE_COMMAND} -Dsource=${CMAKE_SOURCE_DIR} -DMbedTLS_source=${CMAKE_BINARY_DIR}/libs/src/MbedTLS -P ${CMAKE_SOURCE_DIR}/cmake/patch_mbedtls.cmake
		INSTALL_COMMAND echo skip install
		BUILD_BYPRODUCTS ${MBEDTLS_LIBRARIES}
	)
	set_target_properties(MbedTLS PROPERTIES ${EP_PROPS})
	set(MBEDTLS_INCLUDE_DIR ${CMAKE_BINARY_DIR}/libs/src/MbedTLS/include)

	add_dependencies(ssl.ndll MbedTLS)
	# Download project for fat source archive
	add_dependencies(download_deps MbedTLS-download)
else()
	find_package(MbedTLS REQUIRED)
endif()

target_include_directories(ssl.ndll
	PRIVATE
	${MBEDTLS_INCLUDE_DIR}
)

target_compile_definitions(ssl.ndll
	PRIVATE
	-DMBEDTLS_USER_CONFIG_FILE="${CMAKE_CURRENT_SOURCE_DIR}/mbedtls_config.h"
)

if(APPLE)
	find_library(SECURITY_LIBRARY Security REQUIRED)
	find_library(COREFOUNDATION_LIBRARY CoreFoundation REQUIRED)
	target_link_libraries(ssl.ndll ${COREFOUNDATION_LIBRARY} ${SECURITY_LIBRARY})
endif()

target_link_libraries(ssl.ndll libneko ${MBEDTLS_LIBRARIES})

set_target_properties(ssl.ndll
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME ssl
	SUFFIX .ndll
)

install (
	TARGETS ssl.ndll
	DESTINATION ${DEST_NDLL}
)

install(SCRIPT ${NEKO_FLATTEN_SCRIPT})
