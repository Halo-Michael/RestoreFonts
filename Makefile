export TARGET = iphone:clang:13.0:11.0
export ARCHS = arm64 arm64e
export VERSION = 0.3.1
export DEBUG = no
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
	mv rsfonts/.theos/obj/rsfonts com.michael.restorefonts_$(VERSION)_iphoneos-arm/usr/bin
	dpkg -b com.michael.restorefonts_$(VERSION)_iphoneos-arm

extrainst_: clean
	$(CC) extrainst_.c -o extrainst_
	strip extrainst_
	$(LDID) -Sentitlements.xml extrainst_

rsfonts: clean
	cd rsfonts && make

clean:
	rm -rf com.michael.restorefonts_* extrainst_ rsfonts/.theos
