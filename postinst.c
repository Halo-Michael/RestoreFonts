#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        printf("Error in command: \"%s\"\n", cmd);
        exit(WEXITSTATUS(status));
    }
}

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }
    
    run_system("chown root:wheel /usr/bin/rsfonts");
    run_system("chmod 6755 /usr/bin/rsfonts");
    
    if (access("/private/var/tmp/norsfonts", F_OK) != 0) {
        run_system("nohup bash -c \"rsfonts &\" >/dev/null 2>&1");
    } else {
        remove("/private/var/tmp/norsfonts");
    }
    return 0;
}
