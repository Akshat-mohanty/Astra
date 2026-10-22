#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <mach-o/dyld.h>

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

    // Check if a specific URL was passed
    int has_url = 0;
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            has_url = 1;
            break;
        }
    }

    // Allocate arguments: target_bin + user_data_arg + ext_path + --no-first-run + (chrome://newtab if needed) + incoming args + NULL
    int new_argc = argc + 5;
    char **new_argv = malloc((new_argc + 1) * sizeof(char *));

    int idx = 0;
    new_argv[idx++] = target_bin;
    new_argv[idx++] = user_data_arg;
    new_argv[idx++] = ext_path;
    new_argv[idx++] = "--no-first-run";

    for (int i = 1; i < argc; i++) {
        new_argv[idx++] = argv[i];
    }

    if (!has_url) {
        new_argv[idx++] = "chrome://newtab";
    }

    new_argv[idx] = NULL;

    execv(target_bin, new_argv);
    perror("execv failed");
    return 1;
}
