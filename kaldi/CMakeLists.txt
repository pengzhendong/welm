cmake_minimum_required(VERSION 3.14 FATAL_ERROR)
project(kaldi)

if(NOT MSVC)
  # Keep the same with openfst, -fPIC or -fpic
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -pthread -fPIC")
else()
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
  add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
endif()

if(NOT DEFINED FST_INSTALL_DIR)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
  include(ExternalProject)
  include(openfst)
else()
  include_directories(${FST_INSTALL_DIR}/include)
  link_directories(${FST_INSTALL_DIR}/lib)
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_library(utils
  base/kaldi-error.cc
  base/kaldi-math.cc
  util/kaldi-io.cc
  util/parse-options.cc
  util/simple-io-funcs.cc
  util/text-utils.cc
)

if(NOT DEFINED FST_INSTALL_DIR)
  add_dependencies(utils openfst)
endif()

# Arpa binary
add_executable(arpa2fst
  lm/arpa-file-parser.cc
  lm/arpa-lm-compiler.cc
  lmbin/arpa2fst.cc
)
target_link_libraries(arpa2fst PUBLIC fst utils)

# FST tools binary
set(FST_BINS
  fstaddselfloops
  fstdeterminizestar
  fstisstochastic
  fstminimizeencoded
  fsttablecompose
)

foreach(BIN IN LISTS FST_BINS)
  add_executable(${BIN} fstbin/${BIN}.cc fstext/kaldi-fst-io.cc)
  target_link_libraries(${BIN} PUBLIC fst utils)

  if(NOT MSVC)
    target_link_libraries(${BIN} PUBLIC dl)
  endif()
endforeach()
