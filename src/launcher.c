#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <CoreGraphics/CoreGraphics.h>

int main(int argc, char *argv[]) {
    char path[1024];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0) {
        return 1;
    }

    char *dir = dirname(path);
    char target_bin[1024];
    snprintf(target_bin, sizeof(target_bin), "%s/Astra_bin", dir);

    char *home = getenv("HOME");
    char user_data_arg[1024];
    if (home) {
        snprintf(user_data_arg, sizeof(user_data_arg), "--user-data-dir=%s/Library/Application Support/Astra", home);
    } else {
        snprintf(user_data_arg, sizeof(user_data_arg), "--user-data-dir=/tmp/AstraUserData");
    }

    // Path to built-in astra_internal newtab extension inside Resources
    char ext_path[1024];
    snprintf(ext_path, sizeof(ext_path), "--load-extension=%s/../Resources/astra_internal", dir);

    // Detect primary screen resolution for full view
    CGRect screen = CGDisplayBounds(CGMainDisplayID());
    int width = (int)screen.size.width;
    int height = (int)screen.size.height;
    if (width <= 0) width = 1440;
    if (height <= 0) height = 900;

    char win_size_arg[64];
    snprintf(win_size_arg, sizeof(win_size_arg), "--window-size=%d,%d", width, height);
    char win_pos_arg[64] = "--window-position=0,0";

    // Check if an external user-specified URL was passed (filtering out macOS -psn flags)
    int has_user_url = 0;
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "-psn", 4) == 0) continue;
        if (argv[i][0] != '-') {
            has_user_url = 1;
            break;
        }
    }

    // Allocate arguments
    int new_argc = argc + 9;
    char **new_argv = malloc((new_argc + 1) * sizeof(char *));

    int idx = 0;
    new_argv[idx++] = target_bin;
    new_argv[idx++] = user_data_arg;
    new_argv[idx++] = ext_path;
    new_argv[idx++] = "--no-first-run";
    new_argv[idx++] = "--start-maximized";
    new_argv[idx++] = win_size_arg;
    new_argv[idx++] = win_pos_arg;

    for (int i = 1; i < argc; i++) {
        // Skip macOS LaunchServices process serial number argument
        if (strncmp(argv[i], "-psn", 4) == 0) continue;
        new_argv[idx++] = argv[i];
    }

    // Fixed deterministic Astra extension URL on startup
    if (!has_user_url) {
        new_argv[idx++] = "chrome-extension://dhkpjbnpckffnojbmobgkipnajincgmi/index.html";
    }

    new_argv[idx] = NULL;

    execv(target_bin, new_argv);
    perror("execv failed");
    return 1;
}
