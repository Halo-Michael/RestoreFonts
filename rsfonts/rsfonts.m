#include <Foundation/Foundation.h>
#include <sys/snapshot.h>

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        perror(cmd);
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

    clock_t start, stop;
    start = clock();

    int dirfd = open("/", O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        return 2;
    }

    struct attrlist alist = { 0 };
    char abuf[2048];

    alist.commonattr = ATTR_BULK_REQUIRED;

    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return 3;
    } else if (count == 0) {
        printf("No snapshot founded.\n");
        return 4;
    }

    char *p = &abuf[0];
    char *field = p;
    field += sizeof (uint32_t);
    field += sizeof (attribute_set_t);
    attrreference_t ar = *(attrreference_t *)field;
    char *name = field + ar.attr_dataoffset;

    bool existed = false;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (access("/mnt2", F_OK) == 0) {
        if ([[fileManager attributesOfItemAtPath:@"/mnt2" error:nil][@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]){
            existed = true;
        } else {
            [fileManager removeItemAtPath:@"/mnt2" error:nil];
            [fileManager createDirectoryAtPath:@"/mnt2" withIntermediateDirectories:NO attributes:nil error:nil];
        }
    } else {
        [fileManager createDirectoryAtPath:@"/mnt2" withIntermediateDirectories:NO attributes:nil error:nil];
    }

    run_system([[NSString stringWithFormat:@"mount_apfs -s %s / /mnt2", name] UTF8String]);
    [fileManager removeItemAtPath:@"/System/Library/Fonts" error:nil];
    [fileManager copyItemAtPath:@"/mnt2/System/Library/Fonts" toPath:@"/System/Library/Fonts" error:nil];

    run_system([[NSString stringWithFormat:@"umount -f %s@/dev/disk0s1s1", name] UTF8String]);

    if (existed == false) {
        [fileManager removeItemAtPath:@"/mnt2" error:nil];
    }

    [fileManager removeItemAtPath:@"/private/var/mobile/Library/Caches/com.apple.UIStatusBar" error:nil];
    [fileManager removeItemAtPath:@"/private/var/mobile/Library/Caches/com.apple.keyboards/images" error:nil];
    [fileManager removeItemAtPath:@"/private/var/mobile/Library/Caches/TelephonyUI-7" error:nil];
    for (NSString *TUI in [fileManager contentsOfDirectoryAtPath:@"/private/var/mobile/Containers/Data/Application" error:nil]) {
        NSString *metadata = [NSString stringWithFormat:@"/private/var/mobile/Containers/Data/Application/%@/.com.apple.mobile_container_manager.metadata.plist", TUI];
        if (access([metadata UTF8String], F_OK) == 0) {
            NSDictionary *const dict = [NSDictionary dictionaryWithContentsOfFile:metadata];
            if (dict != nil) {
                if ([dict[@"MCMMetadataIdentifier"] isEqualToString:@"com.apple.mobilephone"]) {
                    if (access([[NSString stringWithFormat:@"/private/var/mobile/Containers/Data/Application/%@/Library/Caches/TelephonyUI-7", TUI] UTF8String], F_OK) == 0) {
                        [fileManager removeItemAtPath:[NSString stringWithFormat:@"/private/var/mobile/Containers/Data/Application/%@/Library/Caches/TelephonyUI-7", TUI] error:nil];
                    }
                }
            }
        }
    }

    stop = clock();
    double duration = (double)(stop-start)/CLOCKS_PER_SEC;
    printf("Fonts recovery succeeded.\nUsed %f seconds.\n", duration);

    return 0;
}
