// The OpenCE port's hooks into the PS4 layer (port/): where the Vulkan window system's lines go, Zink's Vulkan entry
// point (the PS4 Mesa's frontends/ps4/ps4_gl.h), Mesa's settings, and the profiler hook the runtime calls for each
// new thread (this port has no profiler).
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <sys/stat.h>

#include "../port/ps4_vk_wsi.h"

extern "C" void host_log(int priority, const char* text);  // port/ps4/host/host_main.c (the checkout)

void opence::ps4::wsi_log(const char* line) {
    host_log(4, line);
}

extern "C" void* zink_ps4_vk_get_instance_proc_addr(void) {
    return opence::ps4::vk_get_instance_proc_addr();
}

extern "C" void ps4_profile_thread_begin() {}

// The crash log's guest part (port/ps4_crashlog.cpp): the guest's own report is in /data/OpenCE/opence.log (its
// fault handler, port/ps4/host/host_debug.c, writes it first).
extern "C" void ps4_crash_guest_info() {}

// Mesa's C++ refers to the GL context's thread-local pointer (a C __thread variable) through its C++ "TLS init"
// function, as a weak symbol nothing defines; create-fself takes an undefined symbol for an import from a system
// module and refuses the eboot. The variable needs no initialisation.
extern "C" void _ZTH23_mesa_glapi_tls_Context() {}

namespace {

// Before main: Mesa reads its settings from the environment when it starts.
__attribute__((constructor(103))) void mesa_settings() {
    // the GPU code of every shader (RADV's) and Zink's pipelines, kept between runs: on this CPU a shader takes the
    // driver a good part of a second
    mkdir("/data/OpenCE", 0777);
    mkdir("/data/OpenCE/mesa", 0777);
    setenv("MESA_SHADER_CACHE_DIR", "/data/OpenCE/mesa", 0);
    setenv("MESA_DISK_CACHE_SINGLE_FILE", "1", 0);
    // Zink's own log next to ours
    setenv("MESA_LOG_FILE", "/data/OpenCE/mesa.log", 0);
}

}  // namespace
