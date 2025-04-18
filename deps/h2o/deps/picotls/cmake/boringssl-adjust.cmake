FUNCTION (BORINGSSL_ADJUST)
    IF (OPENSSL_FOUND AND OPENSSL_VERSION STREQUAL "" AND EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/base.h")
        MESSAGE(STATUS "  BoringSSL found; assuming OpenSSL 1.1.1 compatibility")
        SET(OPENSSL_VERSION "1.1.1" PARENT_SCOPE)
        LIST(GET OPENSSL_CRYPTO_LIBRARIES 0 OPENSSL_ONE_LIB_PATH)
        GET_FILENAME_COMPONENT(OPENSSL_LIBDIR "${OPENSSL_ONE_LIB_PATH}" DIRECTORY)
        SET(LIBDECREPIT_PATH "${OPENSSL_LIBDIR}/libdecrepit.a")
        IF (NOT EXISTS "${LIBDECREPIT_PATH}")
            MESSAGE(FATAL_ERROR "libdecrepit.a was not found under ${OPENSSL_LIBDIR}; maybe you need to manually copy the file there")
        ENDIF ()
        LIST(APPEND OPENSSL_CRYPTO_LIBRARIES "${LIBDECREPIT_PATH}")
        SET(OPENSSL_CRYPTO_LIBRARIES "${OPENSSL_CRYPTO_LIBRARIES}" PARENT_SCOPE)
        IF (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            SET(CXXLIB "-lc++")
        ELSEIF (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            SET(CXXLIB "-lstdc++")
        ELSE ()
            MESSAGE(FATAL_ERROR "do not know how to declare dependency on C++ stdlib even though libssl.a depends on it")
        ENDIF ()
        LIST(APPEND OPENSSL_LIBRARIES "${LIBDECREPIT_PATH}" "${CXXLIB}")
        SET(OPENSSL_LIBRARIES "${OPENSSL_LIBRARIES}" PARENT_SCOPE)
    ENDIF ()
ENDFUNCTION ()
