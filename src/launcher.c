/*
 * Astra Browser Launcher
 *
 * Launches Thorium/Chromium as a PWA (--app=http://127.0.0.1:4545) so that
 * the top toolbar (omnibox, back/forward, icons) is completely hidden while
 * still showing a native tab strip (DesktopPWAsTabStrip feature flag).
 *
 * An embedded single-threaded HTTP server serves the Astra NTP files from
 * Contents/Resources/newtab/ on port 4545.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <CoreGraphics/CoreGraphics.h>

/* ─── Server configuration ──────────────────────────────────────────────── */
#define PORT          4545
#define BACKLOG       8
#define RECV_BUF      4096

static char g_newtab_dir[1024]; /* path to Contents/Resources/newtab */

/* ─── MIME type helper ───────────────────────────────────────────────────── */
static const char *mime_for(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!dot) return "application/octet-stream";
    if (strcmp(dot, ".html") == 0) return "text/html; charset=utf-8";
    if (strcmp(dot, ".js")   == 0) return "application/javascript";
    if (strcmp(dot, ".json") == 0) return "application/json";
    if (strcmp(dot, ".css")  == 0) return "text/css";
    if (strcmp(dot, ".png")  == 0) return "image/png";
    if (strcmp(dot, ".svg")  == 0) return "image/svg+xml";
    if (strcmp(dot, ".ico")  == 0) return "image/x-icon";
    if (strcmp(dot, ".webmanifest") == 0) return "application/manifest+json";
    return "application/octet-stream";
}

/* ─── Send a complete HTTP response ─────────────────────────────────────── */
static void send_response(int fd, int status, const char *status_str,
                          const char *mime, const void *body, size_t body_len) {
    char header[512];
    int hlen = snprintf(header, sizeof(header),
        "HTTP/1.1 %d %s\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n",
        status, status_str, mime, body_len);
    write(fd, header, hlen);
    if (body && body_len > 0) write(fd, body, body_len);
}

/* ─── Serve a file from the newtab directory ─────────────────────────────── */
static void serve_file(int fd, const char *rel_path) {
    /* strip leading slashes */
    while (*rel_path == '/') rel_path++;

    /* default to index.html */
    if (*rel_path == '\0') rel_path = "index.html";

    char full_path[2048];
    snprintf(full_path, sizeof(full_path), "%s/%s", g_newtab_dir, rel_path);

    /* safety: reject paths with ".." */
    if (strstr(full_path, "..")) {
        const char *body = "Forbidden";
        send_response(fd, 403, "Forbidden", "text/plain", body, strlen(body));
        return;
    }

    int file_fd = open(full_path, O_RDONLY);
    if (file_fd < 0) {
        const char *body = "Not Found";
        send_response(fd, 404, "Not Found", "text/plain", body, strlen(body));
        return;
    }

    struct stat st;
    fstat(file_fd, &st);
    size_t fsize = (size_t)st.st_size;

    unsigned char *buf = malloc(fsize);
    if (!buf) { close(file_fd); return; }

    size_t total = 0;
    ssize_t n;
    while (total < fsize &&
           (n = read(file_fd, buf + total, fsize - total)) > 0)
        total += n;
    close(file_fd);

    send_response(fd, 200, "OK", mime_for(rel_path), buf, total);
    free(buf);
}

/* ─── Handle one HTTP connection ─────────────────────────────────────────── */
static void handle_conn(int fd) {
    char buf[RECV_BUF];
    ssize_t n = recv(fd, buf, sizeof(buf) - 1, 0);
    if (n <= 0) { close(fd); return; }
    buf[n] = '\0';

    /* parse first line: METHOD /path HTTP/... */
    char method[8], path[1024];
    if (sscanf(buf, "%7s %1023s", method, path) != 2) {
        close(fd);
        return;
    }

    /* strip query string */
    char *q = strchr(path, '?');
    if (q) *q = '\0';

    /* strip fragment */
    char *f = strchr(path, '#');
    if (f) *f = '\0';

    serve_file(fd, path);
    close(fd);
}

/* ─── Embedded HTTP server (runs in child process) ───────────────────────── */
static void run_server(void) {
    /* ignore SIGCHLD/SIGHUP so the server doesn't become a zombie */
    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP,  SIG_IGN);

    int srv = socket(AF_INET, SOCK_STREAM, 0);
    if (srv < 0) _exit(1);

    int yes = 1;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    struct sockaddr_in addr = {0};
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(PORT);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); /* 127.0.0.1 only */

    if (bind(srv, (struct sockaddr *)&addr, sizeof(addr)) < 0) _exit(1);
    if (listen(srv, BACKLOG) < 0) _exit(1);

    /* serve forever */
    for (;;) {
        int conn = accept(srv, NULL, NULL);
        if (conn < 0) continue;
        handle_conn(conn);
    }
}

/* ─── Wait until the server is accepting connections ─────────────────────── */
static void wait_for_server(void) {
    for (int i = 0; i < 50; i++) {          /* up to ~500 ms */
        int s = socket(AF_INET, SOCK_STREAM, 0);
        if (s < 0) { usleep(20000); continue; }

        struct sockaddr_in addr = {0};
        addr.sin_family      = AF_INET;
        addr.sin_port        = htons(PORT);
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

        int r = connect(s, (struct sockaddr *)&addr, sizeof(addr));
        close(s);
        if (r == 0) return;   /* connected — server is ready */
        usleep(10000);         /* 10 ms */
    }
}

/* ═══════════════════════════════════════════════════════════════════════════
   main
   ═══════════════════════════════════════════════════════════════════════════ */
int main(int argc, char *argv[]) {

    /* resolve our own path to find sibling Resources/ */
    char self_path[1024];
    uint32_t sz = sizeof(self_path);
    if (_NSGetExecutablePath(self_path, &sz) != 0) return 1;

    char *mac_dir = dirname(self_path);  /* …/Astra.app/Contents/MacOS */
    char target_bin[1024];
    snprintf(target_bin, sizeof(target_bin), "%s/Astra_bin", mac_dir);

    /* newtab directory: Contents/Resources/newtab */
    char res_dir[1024];
    snprintf(res_dir, sizeof(res_dir), "%s/../Resources/newtab", mac_dir);
    realpath(res_dir, g_newtab_dir);

    /* extension load arg (overrides chrome://newtab for new tabs) */
    char ext_arg[1024];
    snprintf(ext_arg, sizeof(ext_arg), "--load-extension=%s", g_newtab_dir);

    /* ── user-data dir ── */
    char *home = getenv("HOME");
    char user_data_arg[1024];
    snprintf(user_data_arg, sizeof(user_data_arg),
             "--user-data-dir=%s/Library/Application Support/Astra",
             home ? home : "/tmp");

    /* ── screen size for --window-size ── */
    CGRect screen = CGDisplayBounds(CGMainDisplayID());
    int w = (int)screen.size.width;
    int h = (int)screen.size.height;
    if (w <= 0) w = 1440;
    if (h <= 0) h = 900;

    char win_size_arg[64];
    snprintf(win_size_arg, sizeof(win_size_arg), "--window-size=%d,%d", w, h);

    /* ── fork the embedded HTTP server ── */
    pid_t srv_pid = fork();
    if (srv_pid < 0) { perror("fork"); return 1; }
    if (srv_pid == 0) {
        /* child: become the server, never returns */
        run_server();
        _exit(0);
    }

    /* parent: wait until server is ready before exec'ing Chromium */
    wait_for_server();

    /* ── build Chromium argv ── */
    const char *flags[] = {
        target_bin,
        user_data_arg,
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-search-engine-choice-screen",
        "--start-maximized",
        win_size_arg,
        "--window-position=0,0",
        /* PWA mode: hides toolbar completely */
        "--app=http://127.0.0.1:4545",
        /* Tab strip in app-mode windows; new tabs open to app's new_tab_url */
        "--enable-features=DesktopPWAsTabStrip,DesktopPWAsTabStripCustomizations,DesktopPWAsTabStripSettings",
        /* suppress chrome labs / trending searches clutter */
        "--disable-features=ChromeLabs,OmniboxTrendingZeroPrefixSuggestionsOnNTP,OmniboxZeroSuggestPrefetching",
    };
    int num_flags = (int)(sizeof(flags) / sizeof(flags[0]));

    /* pass through any extra argv (e.g. -psn_... from macOS, or a URL) */
    int extra = 0;
    for (int i = 1; i < argc; i++)
        if (strncmp(argv[i], "-psn", 4) != 0) extra++;

    char **new_argv = malloc((num_flags + extra + 1) * sizeof(char *));
    int idx = 0;
    for (int i = 0; i < num_flags; i++)
        new_argv[idx++] = (char *)flags[i];
    for (int i = 1; i < argc; i++)
        if (strncmp(argv[i], "-psn", 4) != 0)
            new_argv[idx++] = argv[i];
    new_argv[idx] = NULL;

    execv(target_bin, new_argv);
    perror("execv failed");
    return 1;
}
