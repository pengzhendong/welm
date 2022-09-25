set(openfst_SOURCE_DIR ${CMAKE_BINARY_DIR}/openfst-src)

if(NOT MSVC)
  set(openfst_PREFIX_DIR ${CMAKE_BINARY_DIR}/openfst-prefix)

  ExternalProject_Add(openfst
    URL https://github.com/mjansche/openfst/archive/1.6.5.zip
    URL_HASH SHA256=b720357a464f42e181d7e33f60867b54044007f50baedc8f4458a3926f4a5a78
    PREFIX ${openfst_PREFIX_DIR}
    SOURCE_DIR ${openfst_SOURCE_DIR}
    CONFIGURE_COMMAND ${openfst_SOURCE_DIR}/configure --prefix=${openfst_PREFIX_DIR}
    BUILD_COMMAND make -j$(nproc)
  )
  link_directories(${openfst_PREFIX_DIR}/lib)
else()
  add_compile_options(/W0 /wd4244 /wd4267)
  set(HAVE_SCRIPT OFF CACHE BOOL "Build the fstscript" FORCE)
  set(HAVE_COMPACT OFF CACHE BOOL "Build compact" FORCE)
  set(HAVE_CONST OFF CACHE BOOL "Build const" FORCE)
  set(HAVE_GRM OFF CACHE BOOL "Build grm" FORCE)
  set(HAVE_PDT OFF CACHE BOOL "Build pdt" FORCE)
  set(HAVE_MPDT OFF CACHE BOOL "Build mpdt" FORCE)
  set(HAVE_LINEAR OFF CACHE BOOL "Build linear" FORCE)
  set(HAVE_LOOKAHEAD OFF CACHE BOOL "Build lookahead" FORCE)
  set(HAVE_NGRAM OFF CACHE BOOL "Build ngram" FORCE)
  set(HAVE_SPECIAL OFF CACHE BOOL "Build special" FORCE)

  FetchContent_Declare(openfst
    URL https://github.com/kkm000/openfst/archive/refs/tags/win/1.6.5.1.tar.gz
    URL_HASH SHA256=02c49b559c3976a536876063369efc0e41ab374be1035918036474343877046e
  )
  FetchContent_MakeAvailable(openfst)
endif()

include_directories(${openfst_SOURCE_DIR}/src/include)
