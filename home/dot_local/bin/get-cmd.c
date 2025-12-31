#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

#ifdef __APPLE__
#include <libproc.h>
#define PATHBUF_SIZE PROC_PIDPATHINFO_MAXSIZE
#else
#define PATHBUF_SIZE 4096
#endif

int is_version(const char *s) {
    if (!s || !*s) return 0;
    for (int i = 0; s[i]; i++) {
        if (!isdigit(s[i]) && s[i] != '.') return 0;
    }
    return 1;
}

// Get executable path for a PID - OS-specific
int get_exe_path(pid_t pid, char *buf, size_t bufsize) {
#ifdef __APPLE__
    return proc_pidpath(pid, buf, bufsize);
#elif __linux__
    char procpath[64];
    snprintf(procpath, sizeof(procpath), "/proc/%d/exe", pid);
    ssize_t len = readlink(procpath, buf, bufsize - 1);
    if (len > 0) {
        buf[len] = '\0';
        return len;
    }
    return 0;
#else
    return 0;
#endif
}

// Check if path matches Claude's versioned binary
int is_claude_path(const char *path) {
#ifdef __APPLE__
    return strstr(path, "claude/versions") != NULL;
#elif __linux__
    // Adjust for Linux Claude install path if different
    return strstr(path, "claude/versions") != NULL ||
           strstr(path, ".claude/") != NULL;
#else
    return 0;
#endif
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <command> <tty>\n", argv[0]);
        return 1;
    }
    
    const char *cmd = argv[1];
    const char *tty = argv[2];
    
    if (!is_version(cmd)) {
        printf("%s\n", cmd);
        return 0;
    }
    
    // Strip /dev/ prefix
    if (strncmp(tty, "/dev/", 5) == 0) tty += 5;
    
    char pscmd[256];
    snprintf(pscmd, sizeof(pscmd), "ps -t %s -o pid=,ucomm= 2>/dev/null", tty);
    
    FILE *fp = popen(pscmd, "r");
    if (!fp) { printf("%s\n", cmd); return 0; }
    
    char line[256];
    pid_t found_pid = 0;
    
    while (fgets(line, sizeof(line), fp)) {
        pid_t pid;
        char ucomm[128];
        if (sscanf(line, "%d %127s", &pid, ucomm) == 2) {
            if (strcmp(ucomm, cmd) == 0) {
                found_pid = pid;
                break;
            }
        }
    }
    pclose(fp);
    
    if (found_pid > 0) {
        char pathbuf[PATHBUF_SIZE];
        if (get_exe_path(found_pid, pathbuf, sizeof(pathbuf)) > 0) {
            if (is_claude_path(pathbuf)) {
                printf("claude\n");
                return 0;
            }
            char *name = strrchr(pathbuf, '/');
            if (name) {
                printf("%s\n", name + 1);
                return 0;
            }
        }
    }
    
    printf("%s\n", cmd);
    return 0;
}
