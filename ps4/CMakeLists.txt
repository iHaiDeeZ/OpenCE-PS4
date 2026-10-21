# The OpenCE eboot: the PS4 host of OpenCE's ps4 branch (port/ps4/host in the checkout: the guest image's loader,
# memory, threads, system calls, pads, sound and OpenGL ES), the platform layer's posix_*.c files that run in the host,
# Mesa (Zink on RADV with the PS4 GL frontend, scripts/build-mesa.sh), and the PS4 layer (port/). The game itself is
# the guest image, build/ps4/halo_guest.elf in the checkout (ninja ps4), packaged beside the eboot.
# Configured by scripts/build-opence.sh with toolchain/ps4-opence.cmake and toolchain/ps4-love-style.cmake.
cmake_minimum_required(VERSION 3.20)
project(opence C CXX ASM)

set(CMAKE_CXX_STANDARD 20)
set(PORT ${CMAKE_CURRENT_SOURCE_DIR}/../port)
set(OPENCE_SRC "$ENV{HOME}/opence-build/src/OpenCE" CACHE PATH "OpenCE checkout (branch ps4)")
set(MESA_SRC "$ENV{HOME}/opence-build/src/mesa" CACHE PATH "the PS4 Mesa's source (branch opence)")
set(OPENCE_VERSION "00.00" CACHE STRING "the package's version")

set(HOST ${OPENCE_SRC}/port/ps4/host)
set(LINUX_SRC ${OPENCE_SRC}/port/linux/src)
set(THIRD_PARTY ${OPENCE_SRC}/port/third_party)
set(GENERATED ${OPENCE_SRC}/build/ps4/host)

file(GLOB HOST_SOURCES ${HOST}/*.c)
file(GLOB MINIUPNPC_SOURCES ${THIRD_PARTY}/miniupnpc/src/*.c)
file(GLOB MBEDTLS_SOURCES ${THIRD_PARTY}/mbedtls/library/*.c)

add_executable(eboot opence_port.cpp ${PORT}/ps4_vk_wsi.cpp ${PS4_RUNTIME_SOURCES}
    ${HOST_SOURCES} ${OPENCE_SRC}/port/android/host/host_watch_hash.c
    ${GENERATED}/host_import_table.c
    ${LINUX_SRC}/posix_files.c ${LINUX_SRC}/posix_net.c ${LINUX_SRC}/posix_upnp.c ${LINUX_SRC}/posix_dtls.c
    ${MINIUPNPC_SOURCES} ${MBEDTLS_SOURCES})
target_include_directories(eboot PRIVATE
    ${HOST} ${GENERATED} ${OPENCE_SRC}/port/android/include ${OPENCE_SRC}/port/android/host ${LINUX_SRC}
    ${OPENCE_SRC}/build/ps4/third_party/SDL3/include ${MESA_SRC}/include ${MESA_SRC}/src/gallium/frontends/ps4
    ${THIRD_PARTY}/mbedtls/include ${THIRD_PARTY}/mbedtls/library
    ${THIRD_PARTY}/miniupnpc/include ${THIRD_PARTY}/miniupnpc/src)
target_compile_definitions(eboot PRIVATE OPENCE_PS4_VERSION="${OPENCE_VERSION}"
    MINIUPNP_STATICLIB MINIUPNPC_SET_SOCKET_TIMEOUT MINIUPNPC_GET_SRC_ADDR)
target_compile_options(eboot PRIVATE -Wno-everything)
set_source_files_properties(${HOST_SOURCES} PROPERTIES COMPILE_OPTIONS "-Wall;-Wno-unused-function")
set_source_files_properties(${LINUX_SRC}/posix_files.c ${LINUX_SRC}/posix_net.c ${LINUX_SRC}/posix_upnp.c
    ${LINUX_SRC}/posix_dtls.c PROPERTIES COMPILE_OPTIONS "-include;${HOST}/host_posix_compat.h")

# Mesa: RADV as whole archives, as Mesa's own shared-library link has it: its dispatch tables refer to entry points
# through weak symbols, which don't pull archive members (they'd silently be NULL); libvulkan_radeon.a holds the
# Vulkan runtime too. Zink and Mesa's GL with the PS4 frontend as ordinary archives (Zink carries its own copy of
# the Vulkan dispatch tables, which RADV's then stand for).
set(RADV_LIBS
    src/amd/vulkan/libvulkan_radeon.a src/amd/common/libamd_common.a src/amd/compiler/libaco.a
    src/amd/addrlib/libaddrlib.a src/vulkan/util/libvulkan_util.a src/compiler/spirv/libvtn.a src/compiler/nir/libnir.a
    src/compiler/libcompiler.a src/util/libmesa_util.a src/util/libmesa_util_simd.a src/util/libmesa_util_clflush.a
    src/util/libmesa_util_clflushopt.a src/util/libparson.a src/util/libxmlconfig.a src/util/blake3/libblake3.a
    src/c11/impl/libmesa_util_c11.a)
set(GL_LIBS
    src/gallium/frontends/ps4/libps4gl.a src/gallium/drivers/zink/libzink.a src/gallium/auxiliary/libgallium.a
    src/mesa/libmesa.a src/mesa/libmesa_sse41.a src/mesa/glapi/glapi/libglapi_bridge.a src/mesa/glapi/shared-glapi/libglapi.a
    src/compiler/glsl/libglsl.a src/compiler/glsl/glcpp/libglcpp.a)
list(TRANSFORM RADV_LIBS PREPEND "${PS4_MESA_BUILD}/")
list(TRANSFORM GL_LIBS PREPEND "${PS4_MESA_BUILD}/")
target_link_libraries(eboot PRIVATE --whole-archive ${RADV_LIBS} --no-whole-archive ${GL_LIBS} ${PS4_SYSROOT}/lib/libz.a)
target_link_libraries(eboot PRIVATE
    SceSysmodule SceSystemService SceUserService SceVideoOut SceAudioOut ScePad SceNet SceNetCtl)
ps4_add_eboot(eboot)
