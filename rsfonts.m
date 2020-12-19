#import <Foundation/Foundation.h>
#import <copyfile.h>
#import <removefile.h>
#import <sys/mount.h>
#import <sys/snapshot.h>
#import <sys/stat.h>

@interface LSApplicationProxy : NSObject<NSSecureCoding>

@property (nonatomic, readonly) NSURL *dataContainerURL;

+ (id)applicationProxyForIdentifier:(id)arg1;

@end

void removeCacheFromID(NSString *bundleID) {
    removefile([[[[[LSApplicationProxy applicationProxyForIdentifier:bundleID] dataContainerURL] path] stringByAppendingString:@"/Library/Caches/TelephonyUI-7"] UTF8String], NULL, REMOVEFILE_RECURSIVE);
    removefile([[[[[LSApplicationProxy applicationProxyForIdentifier:bundleID] dataContainerURL] path] stringByAppendingString:@"/Library/Caches/TelephonyUI-8"] UTF8String], NULL, REMOVEFILE_RECURSIVE);
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
    printf("Fonts recovering...\n");

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

    count = fs_snapshot_mount(dirfd, "/mnt2", name, 0);
    close(dirfd);
    if (count < 0) {
        perror("fs_snapshot_mount");
        return 5;
    }

    removefile("/System/Library/Fonts", NULL, REMOVEFILE_RECURSIVE);
    copyfile("/mnt2/System/Library/Fonts", "/System/Library/Fonts", NULL, COPYFILE_ALL | COPYFILE_RECURSIVE);

    unmount("/mnt2", MNT_FORCE);

    if (!existed) {
        removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
    }

    removefile("/private/var/mobile/Library/Caches/com.apple.UIStatusBar", NULL, REMOVEFILE_RECURSIVE);
    removefile("/private/var/mobile/Library/Caches/com.apple.keyboards/images", NULL, REMOVEFILE_RECURSIVE);
    removefile("/private/var/mobile/Library/Caches/TelephonyUI-7", NULL, REMOVEFILE_RECURSIVE);
    removefile("/private/var/mobile/Library/Caches/TelephonyUI-8", NULL, REMOVEFILE_RECURSIVE);
    removeCacheFromID(@"com.apple.mobilephone");
    removeCacheFromID(@"com.apple.InCallService");
    removeCacheFromID(@"com.apple.CoreAuthUI");

    stop = clock();
    double duration = (double)(stop-start)/CLOCKS_PER_SEC;
    printf("Fonts recover succeeded.\nUsed %f seconds.\n", duration);

    return 0;
}
