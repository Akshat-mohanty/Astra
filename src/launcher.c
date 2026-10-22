#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <sys/stat.h>
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

    // Detect primary screen resolution for full view
    CGRect screen = CGDisplayBounds(CGMainDisplayID());
    int width = (int)screen.size.width;
    int height = (int)screen.size.height;
    if (width <= 0) width = 1440;
    if (height <= 0) height = 900;

    char win_size_arg[64];
    snprintf(win_size_arg, sizeof(win_size_arg), "--window-size=%d,%d", width, height);
    char win_pos_arg[64] = "--window-position=0,0";

    // Check if an external user URL was passed
    int has_user_url = 0;
    const char *initial_url = "chrome://newtab";
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "-psn", 4) == 0) continue;
        if (argv[i][0] != '-') {
            has_user_url = 1;
            initial_url = argv[i];
            break;
        }
    }

    // Minimal flags: disable clutter, trending searches dropdown, labs, and ensure edge-to-edge full view
    const char *flags[] = {
        target_bin,
        user_data_arg,
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-search-engine-choice-screen",
        "--start-maximized",
        win_size_arg,
        win_pos_arg,
        "--disable-features=ChromeLabs,SidePanel,SidePanelPinning,LensOverlay,OmniboxTrendingZeroPrefixSuggestionsOnNTP,OmniboxZeroSuggestPrefetching",
        "--homepage=chrome://newtab",
        initial_url
    };
    int num_flags = sizeof(flags) / sizeof(flags[0]);

    int new_argc = num_flags + argc;
    char **new_argv = malloc((new_argc + 1) * sizeof(char *));

    int idx = 0;
    for (int i = 0; i < num_flags; i++) {
        new_argv[idx++] = (char *)flags[i];
    }

    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "-psn", 4) == 0) continue;
        if (has_user_url && argv[i][0] != '-') continue;
        new_argv[idx++] = argv[i];
    }

    new_argv[idx] = NULL;

    execv(target_bin, new_argv);
    perror("execv failed");
    return 1;
}
