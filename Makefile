TARGET = RestoreFonts
VERSION = 0.1.1
CC = xcrun -sdk iphoneos clang -arch arm64 -miphoneos-version-min=11.0
LDID = ldid

.PHONY: all clean

all: clean preinst postinst rsfonts
	mkdir com.michael.RestoreFonts-$(VERSION)_iphoneos-arm
	mkdir com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/DEBIAN
	mv preinst com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/usr/bin
	mv rsfonts com.michael.RestoreFonts-$(VERSION)_iphoneos-arm/usr/bin
	dpkg -b com.michael.RestoreFonts-$(VERSION)_iphoneos-arm

preinst: clean
	$(CC) preinst.c -o preinst
	strip preinst
	$(LDID) -Sentitlements.xml preinst

postinst: clean
	$(CC) postinst.c -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

rsfonts: clean
	$(CC) rsfonts.c -o rsfonts
	strip rsfonts
	$(LDID) -Sentitlements-apfs.xml rsfonts

clean:
	rm -rf com.michael.RestoreFonts-*
	rm -f preinst postinst rsfonts
