#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
extern char **environ;

int run_cmd(char *cmd)
{
    pid_t pid;
    char *argv[] = {"sh", "-c", cmd, NULL};
    int status = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, environ);
    if (status == 0) {
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    }
    return status;
}

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    
    if (access("/private/var/tmp/norsfonts", F_OK) != 0) {
        run_cmd("nohup bash -c \"rsfonts &\" >/dev/null 2>&1");
    } else {
        remove("/private/var/tmp/norsfonts");
    }
    return 0;
}
