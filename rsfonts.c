#include <fcntl.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/snapshot.h>
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
    
    int dirfd = open("/", O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        exit(1);
    } else if (count == 0) {
        perror("No snapshot founded");
        exit(1);
    }
    
    char *p = &abuf[0];
    char *field = p;
    uint32_t len = *(uint32_t *)field;
    field += sizeof (uint32_t);
    attribute_set_t attrs = *(attribute_set_t *)field;
    field += sizeof (attribute_set_t);
    attrreference_t ar = *(attrreference_t *)field;
    char *name = field + ar.attr_dataoffset;
    
    bool exisit = 0;
    if (access("/mnt2", 0)) {
        run_cmd("mkdir /mnt2");
    } else {
        exisit = 1;
    }
    
    char command[200];
    sprintf(command, "mount_apfs -s %s / /mnt2", name);
    if (run_cmd(command) == 0) {
        run_cmd("rm -rf /System/Library/Fonts/*");
        run_cmd("cp -a /mnt2/System/Library/Fonts/* /System/Library/Fonts");
    } else {
        perror("Mount failed");
        exit(1);
    }
    
    sprintf(command, "umount -f %s@/dev/disk0s1s1", name);
    run_cmd(command);
    
    if (!exisit) {
        run_cmd("rm -rf /mnt2");
    }
    
    run_cmd("rm -rf /private/var/mobile/Library/Caches/com.apple.UIStatusBar/*");
    run_cmd("rm -rf /private/var/mobile/Library/Caches/com.apple.keyboards/images/*");
    
    run_cmd("killall -9 SpringBoard");
    
    return 0;
}
