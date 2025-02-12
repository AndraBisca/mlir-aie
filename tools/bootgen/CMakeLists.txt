#
# This file is licensed under the Apache License v2.0 with LLVM Exceptions. See
# https://llvm.org/LICENSE.txt for license information. SPDX-License-Identifier:
# Apache-2.0 WITH LLVM-exception
#
# (c) Copyright 2024 Xilinx Inc.

set(BOOTGEN_SOURCE ${PROJECT_SOURCE_DIR}/third_party/bootgen)
set(libsources
    cdo-alloc.c
    cdo-binary.c
    cdo-command.c
    cdo-load.c
    cdo-metadata.c
    cdo-npi.c
    cdo-overlay.c
    cdo-raw.c
    cdo-source.c
    cJSON.c
    authentication.cpp
    authentication-versal.cpp
    authentication-zynq.cpp
    authentication-zynqmp.cpp
    authkeys.cpp
    authkeys-versal.cpp
    bifoptions.cpp
    bif.tab.cpp
    bif.yy.cpp
    binary.cpp
    binary-versal.cpp
    binfile.cpp
    bitutils.cpp
    bitutils-versal.cpp
    bootheader.cpp
    bootheader-versal.cpp
    bootheader-zynq.cpp
    bootheader-zynqmp.cpp
    bootimage.cpp
    bootimage-versal.cpp
    bootimage-zynq.cpp
    bootimage-zynqmp.cpp
    checksum.cpp
    checksum-versal.cpp
    cmdoptions.tab.cpp
    cmdoptions.yy.cpp
    elftools.cpp
    encryption.cpp
    encryption-versal.cpp
    encryption-versalnet.cpp
    encryption-zynq.cpp
    encryption-zynqmp.cpp
    encryptutils.cpp
    hash.cpp
    imageheadertable.cpp
    imageheadertable-versal.cpp
    imageheadertable-zynq.cpp
    imageheadertable-zynqmp.cpp
    kdf.cpp
    Keccak-compact.cpp
    Keccak-compact-versal.cpp
    logger.cpp
    # main.cpp
    mcsfile.cpp
    options.cpp
    outputfile.cpp
    outputfile-versal.cpp
    parsing.cpp
    partition.cpp
    partitionheadertable.cpp
    partitionheadertable-versal.cpp
    partitionheadertable-zynq.cpp
    partitionheadertable-zynqmp.cpp
    partition-versal.cpp
    postprocess.cpp
    readimage.cpp
    readimage-versal.cpp
    readimage-zynq.cpp
    readimage-zynqmp.cpp
    reginit.cpp
    reginit.tab.cpp
    reginit.yy.cpp
    verifyimage-versal.cpp
    verifyimage-zynqmp.cpp)
list(TRANSFORM libsources PREPEND ${BOOTGEN_SOURCE}/)

if(NOT CMAKE_SYSTEM_NAME MATCHES "Windows")
  # Windows fails CI because OpenSSL is not installed

  # Macos fails because no malloc.h
  # malloc.h is deprecated and should not be used
  # https://stackoverflow.com/a/56463133
  # If you want to use malloc, then include stdlib.h
  file(READ ${BOOTGEN_SOURCE}/cdo-npi.c FILE_CONTENTS)
  string(REPLACE "#include <malloc.h>" "" FILE_CONTENTS "${FILE_CONTENTS}")
  file(WRITE ${BOOTGEN_SOURCE}/cdo-npi.c "${FILE_CONTENTS}")

  file(READ ${BOOTGEN_SOURCE}/cdo-alloc.c FILE_CONTENTS)
  string(REPLACE "#include <malloc.h>" "" FILE_CONTENTS "${FILE_CONTENTS}")
  file(WRITE ${BOOTGEN_SOURCE}/cdo-alloc.c "${FILE_CONTENTS}")

  find_package(OpenSSL REQUIRED)
  if (OPENSSL_FOUND)
    message (STATUS "OpenSSL found")
    message (STATUS "OpenSSL include directories:" ${OPENSSL_INCLUDE_DIR})
  else()
    message (FATAL_ERROR "OpenSSL Not found.")
  endif()

  add_library(Bootgen STATIC ${libsources})
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    set(bootgen_warning_ignores
        -Wno-reorder
        -Wno-register
        -Wno-unused-private-field
        -Wno-deprecated-register
        -Wno-overloaded-virtual
        -Wno-deprecated-declarations
        -Wno-pointer-bool-conversion
        -Wno-unused-const-variable
        -Wno-tautological-overlap-compare
        -Wno-dynamic-class-memaccess
        -Wno-misleading-indentation
        -Wno-suggest-override
        -Wno-non-virtual-dtor
        -Wno-deprecated-copy
        -Wno-cast-qual
        -Wno-date-time
        -Wno-implicit-fallthrough
        -Wno-incompatible-pointer-types-discards-qualifiers
        -Wno-sign-compare
        -Wno-covered-switch-default)
  else()
    set(bootgen_warning_ignores)
  endif()
  target_compile_options(Bootgen PRIVATE ${bootgen_warning_ignores})
  target_include_directories(Bootgen PRIVATE ${BOOTGEN_SOURCE} ${OPENSSL_INCLUDE_DIR})
  install(
    TARGETS Bootgen
    DESTINATION lib
    EXPORT Bootgen)

  add_executable(bootgen ${BOOTGEN_SOURCE}/main.cpp)
  target_include_directories(bootgen PUBLIC ${BOOTGEN_SOURCE} ${OPENSSL_INCLUDE_DIR})
  target_compile_options(bootgen PRIVATE ${bootgen_warning_ignores})
  target_link_libraries(bootgen Bootgen Bootgen OpenSSL::SSL)
  install(TARGETS bootgen)

  add_library(cdo_driver STATIC ${BOOTGEN_SOURCE}/cdo-driver/cdo_driver.c)
  target_include_directories(
    cdo_driver PUBLIC $<BUILD_INTERFACE:${BOOTGEN_SOURCE}/cdo-driver>
                      $<INSTALL_INTERFACE:include/cdo_driver>)
  target_compile_options(cdo_driver PRIVATE -Wno-cast-qual -Wno-sign-compare)
  install(
    TARGETS cdo_driver
    DESTINATION lib
    EXPORT cdo_driver)
  install(EXPORT cdo_driver DESTINATION lib/cmake/aie)

endif() # NOT MSVC
