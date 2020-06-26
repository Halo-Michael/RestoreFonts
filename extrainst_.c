#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        perror(cmd);
        exit(WEXITSTATUS(status));
    }
}

int main(int argc, const char **argv) {
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    chown("/usr/bin/rsfonts", 0, 0);
    chmod("/usr/bin/rsfonts", 06755);

    if (strcmp(argv[1], "install") == 0) {
        run_system("rsfonts");
        char *cydia_env = getenv("CYDIA");
        if (cydia_env != NULL) {
            int cydiaFd = (int)strtoul(cydia_env, NULL, 10);
            if (cydiaFd != 0) {
                write(cydiaFd, "finish:restart\n", 15);
            }
        }
    }
    return 0;
}
