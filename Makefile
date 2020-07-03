TARGET = rsfonts
VERSION = 0.3.1
CC = xcrun -sdk ${THEOS}/sdks/iPhoneOS13.0.sdk clang -arch arm64 -arch arm64e -miphoneos-version-min=11.0
LDID = ldid

.PHONY: all clean

all: clean extrainst_ rsfonts
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	mv extrainst_ com.michael.restorefonts_$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr/bin
	mv rsfonts com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr/bin
	dpkg -b com.michael.restorefonts_$(VERSION)_iphoneos-arm

extrainst_: clean
	$(CC) extrainst_.c -o extrainst_
	strip extrainst_
	$(LDID) -Sentitlements.xml extrainst_

rsfonts: clean
	$(CC) -fobjc-arc rsfonts.m -o rsfonts
	strip rsfonts
	$(LDID) -Sentitlements-apfs.xml rsfonts

clean:
	rm -rf com.michael.restorefonts_* extrainst_ rsfonts
