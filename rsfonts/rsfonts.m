#include <sys/snapshot.h>
#include <sys/stat.h>

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        printf("Error in command: \"%s\"\n", cmd);
        exit(WEXITSTATUS(status));
    }
}

int main() {
    if (getuid() != 0) {
        setuid(0);
    }
    
    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }
    
    int dirfd = open("/", O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        return 1;
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return 1;
    } else if (count == 0) {
        perror("No snapshot founded.");
        return 1;
    }
    
    char *p = &abuf[0];
    char *field = p;
    field += sizeof (uint32_t);
    field += sizeof (attribute_set_t);
    attrreference_t ar = *(attrreference_t *)field;
    char *name = field + ar.attr_dataoffset;
    
    bool existed = false;
    if (access("/mnt2", F_OK) == 0) {
        struct stat st;
        stat("/mnt2", &st);
        if (S_ISDIR(st.st_mode)){
            existed = true;
        } else {
            remove("/mnt2");
            run_system("mkdir /mnt2");
        }
    } else {
        run_system("mkdir /mnt2");
    }

    run_system([NSString stringWithFormat:@"mount_apfs -s %s / /mnt2", name].UTF8String);
    run_system("rm -rf /System/Library/Fonts");
    run_system("cp -a /mnt2/System/Library/Fonts /System/Library");

    run_system([NSString stringWithFormat:@"umount -f %s@/dev/disk0s1s1", name].UTF8String);
    
    if (existed == false) {
        run_system("rm -rf /mnt2");
    }
    
    run_system("rm -rf /private/var/mobile/Library/Caches/com.apple.UIStatusBar/*");
    run_system("rm -rf /private/var/mobile/Library/Caches/com.apple.keyboards/images/*");
    run_system("rm -rf /private/var/mobile/Library/Caches/TelephonyUI-7/*");
    
    run_system("killall -9 backboardd");
    
    return 0;
}
