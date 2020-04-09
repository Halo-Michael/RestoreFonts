TARGET = RestoreFonts
VERSION = 0.1.2
CC = xcrun -sdk iphoneos clang -arch arm64 -arch arm64e -miphoneos-version-min=11.0
LDID = ldid

.PHONY: all clean

all: clean preinst postinst rsfonts
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	mv preinst com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr/bin
	mv rsfonts/.theos/obj/rsfonts com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr/bin
	dpkg -b com.michael.restorefonts_$(VERSION)_iphoneos-arm

preinst: clean
	$(CC) preinst.c -o preinst
	strip preinst
	$(LDID) -Sentitlements.xml preinst

postinst: clean
	$(CC) postinst.c -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

rsfonts: clean
	sh make-rsfonts.sh

clean:
	rm -rf com.michael.restorefonts_* preinst postinst rsfonts/.theos
