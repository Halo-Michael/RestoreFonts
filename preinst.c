#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    
    remove("/private/var/tmp/norsfonts");
    if (strcmp(argv[1], "upgrade") == 0) {
        FILE *fp = fopen("/private/var/tmp/norsfonts","a+");
        fclose(fp);
    }
    return 0;
}
