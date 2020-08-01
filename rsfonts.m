#import <Foundation/Foundation.h>
#include <copyfile.h>
#include <removefile.h>
#include <sys/snapshot.h>
#include <sys/stat.h>

@interface LSApplicationProxy : NSObject<NSSecureCoding>

@property (nonatomic, readonly) NSURL *dataContainerURL;

+ (id)applicationProxyForIdentifier:(id)arg1;

@end

const char *cachePach(const char *bundleid) {
    return [[NSString stringWithFormat:@"%@/Library/Caches/TelephonyUI-7", [[[LSApplicationProxy applicationProxyForIdentifier:[[NSString alloc] initWithUTF8String:bundleid]] dataContainerURL] path]] UTF8String];
}

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

    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/mnt2" isDirectory:&existed]) {
        if (!existed) {
            removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
        }
    }
    if (!existed) {
        mkdir("/mnt2", 00755);
    }

    run_system([[NSString stringWithFormat:@"mount_apfs -s %s / /mnt2", name] UTF8String]);
    removefile("/System/Library/Fonts", NULL, REMOVEFILE_RECURSIVE);
    copyfile("/mnt2/System/Library/Fonts", "/System/Library/Fonts", NULL, COPYFILE_ALL | COPYFILE_RECURSIVE);

    run_system([[NSString stringWithFormat:@"umount -f %s@/dev/disk0s1s1", name] UTF8String]);

    if (!existed) {
        removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
    }

    removefile("/private/var/mobile/Library/Caches/com.apple.UIStatusBar", NULL, REMOVEFILE_RECURSIVE);
    removefile("/private/var/mobile/Library/Caches/com.apple.keyboards/images", NULL, REMOVEFILE_RECURSIVE);
    removefile("/private/var/mobile/Library/Caches/TelephonyUI-7", NULL, REMOVEFILE_RECURSIVE);
    removefile(cachePach("com.apple.mobilephone"), NULL, REMOVEFILE_RECURSIVE);
    removefile(cachePach("com.apple.InCallService"), NULL, REMOVEFILE_RECURSIVE);
    removefile(cachePach("com.apple.CoreAuthUI"), NULL, REMOVEFILE_RECURSIVE);

    stop = clock();
    double duration = (double)(stop-start)/CLOCKS_PER_SEC;
    printf("Fonts recovery succeeded.\nUsed %f seconds.\n", duration);

    return 0;
}
