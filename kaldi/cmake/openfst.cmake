set(openfst_SOURCE_DIR ${CMAKE_BINARY_DIR}/openfst-src)
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
include_directories(${openfst_SOURCE_DIR}/src/include)
