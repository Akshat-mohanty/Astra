#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <CoreGraphics/CoreGraphics.h>

#define SERVER_PORT 4545

static const char *get_mime_type(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!dot) return "application/octet-stream";
    if (strcasecmp(dot, ".html") == 0) return "text/html; charset=utf-8";
    if (strcasecmp(dot, ".js") == 0)   return "application/javascript; charset=utf-8";
    if (strcasecmp(dot, ".css") == 0)  return "text/css; charset=utf-8";
    if (strcasecmp(dot, ".png") == 0)  return "image/png";
    if (strcasecmp(dot, ".jpg") == 0 || strcasecmp(dot, ".jpeg") == 0) return "image/jpeg";
    if (strcasecmp(dot, ".svg") == 0)  return "image/svg+xml";
    if (strcasecmp(dot, ".json") == 0) return "application/json";
    if (strcasecmp(dot, ".ico") == 0)  return "image/x-icon";
    return "application/octet-stream";
}

static void serve_file(int client_fd, const char *web_root, const char *req_path) {
    // Handle in-page new tab / window requests
    if (strcmp(req_path, "/__astra_new_tab__") == 0) {
        system("open -n -a /Applications/Astra.app &");
        const char *ok_resp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK";
        send(client_fd, ok_resp, strlen(ok_resp), 0);
        return;
    }

    char clean_path[1024];
    if (strcmp(req_path, "/") == 0 || strcmp(req_path, "") == 0) {
        snprintf(clean_path, sizeof(clean_path), "%s/index.html", web_root);
    } else {
        const char *rel = req_path;
        while (*rel == '/') rel++;
        if (strstr(rel, "..")) {
            const char *bad = "HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
            send(client_fd, bad, strlen(bad), 0);
            return;
        }
        snprintf(clean_path, sizeof(clean_path), "%s/%s", web_root, rel);
    }

    int fd = open(clean_path, O_RDONLY);
    if (fd < 0) {
        const char *not_found = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        send(client_fd, not_found, strlen(not_found), 0);
        return;
    }

    struct stat st;
    fstat(fd, &st);
    size_t fsize = (size_t)st.st_size;
    const char *mime = get_mime_type(clean_path);

    char header[512];
    int hlen = snprintf(header, sizeof(header),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "Cache-Control: no-cache\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n", mime, fsize);
    send(client_fd, header, hlen, 0);

    char buf[16384];
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        send(client_fd, buf, n, 0);
    }
    close(fd);
}

static void run_daemon_server(const char *web_root) {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) exit(1);

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    addr.sin_port = htons(SERVER_PORT);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(server_fd);
        exit(1);
    }

    if (listen(server_fd, 32) < 0) {
        close(server_fd);
        exit(1);
    }

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) {
            if (errno == EINTR) continue;
            break;
        }

        char req_buf[2048];
        ssize_t r = recv(client_fd, req_buf, sizeof(req_buf) - 1, 0);
        if (r > 0) {
            req_buf[r] = '\0';
            if (strncmp(req_buf, "GET ", 4) == 0) {
                char *path_start = req_buf + 4;
                char *path_end = strchr(path_start, ' ');
                if (path_end) {
                    *path_end = '\0';
                    char *q = strchr(path_start, '?');
                    if (q) *q = '\0';
                    serve_file(client_fd, web_root, path_start);
                }
            }
        }
        close(client_fd);
    }
    close(server_fd);
    exit(0);
}

static int is_port_open(int port) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return 0;

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    addr.sin_port = htons(port);

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 30000;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char*)&tv, sizeof(tv));

    int res = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);
    return (res == 0);
}

int main(int argc, char *argv[]) {
    char path[1024];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0) {
        return 1;
    }

    char *dir = dirname(path);
    char target_bin[1024];
    snprintf(target_bin, sizeof(target_bin), "%s/Astra_bin", dir);

    char web_root[1024];
    snprintf(web_root, sizeof(web_root), "%s/../Resources/newtab", dir);
    struct stat st;
    if (stat(web_root, &st) != 0) {
        snprintf(web_root, sizeof(web_root), "/Users/akshatmohanty/Astra/src/newtab");
    }

    // Ensure local micro-server is running
    if (!is_port_open(SERVER_PORT)) {
        pid_t pid = fork();
        if (pid == 0) {
            setsid();
            int devnull = open("/dev/null", O_RDWR);
            if (devnull >= 0) {
                dup2(devnull, STDIN_FILENO);
                dup2(devnull, STDOUT_FILENO);
                dup2(devnull, STDERR_FILENO);
                if (devnull > 2) close(devnull);
            }
            run_daemon_server(web_root);
            _exit(0);
        }
        for (int t = 0; t < 25; t++) {
            usleep(10000);
            if (is_port_open(SERVER_PORT)) break;
        }
    }

    // Insert Astra AppKit hook to intercept Cmd+T and Cmd+N so they never revert to normal Chromium look
    char dylib_path[1024];
    snprintf(dylib_path, sizeof(dylib_path), "%s/../Frameworks/libastra_hook.dylib", dir);
    struct stat dst;
    if (stat(dylib_path, &dst) == 0) {
        setenv("DYLD_INSERT_LIBRARIES", dylib_path, 1);
    }

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
    char target_app_arg[1024];
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "-psn", 4) == 0) continue;
        if (argv[i][0] != '-') {
            has_user_url = 1;
            const char *u = argv[i];
            if (strncmp(u, "http://", 7) == 0 || strncmp(u, "https://", 8) == 0) {
                snprintf(target_app_arg, sizeof(target_app_arg), "--app=%s", u);
            } else {
                snprintf(target_app_arg, sizeof(target_app_arg), "--app=https://%s", u);
            }
            break;
        }
    }

    if (!has_user_url) {
        snprintf(target_app_arg, sizeof(target_app_arg), "--app=http://127.0.0.1:%d", SERVER_PORT);
    }

    int new_argc = argc + 10;
    char **new_argv = malloc((new_argc + 1) * sizeof(char *));

    int idx = 0;
    new_argv[idx++] = target_bin;
    new_argv[idx++] = user_data_arg;
    new_argv[idx++] = "--no-first-run";
    new_argv[idx++] = "--no-default-browser-check";
    new_argv[idx++] = "--disable-search-engine-choice-screen";
    new_argv[idx++] = "--start-maximized";
    new_argv[idx++] = win_size_arg;
    new_argv[idx++] = win_pos_arg;
    new_argv[idx++] = target_app_arg;

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
