# This package should NOT be needed for "normal" Android systems.
# Please do NOT depend on this package; do NOT include this package in
# `TERMUX_PKG_{DEPENDS,RECOMMENDS}` of other packages.
TERMUX_PKG_HOMEPAGE=https://android.googlesource.com/platform/frameworks/base/+/master/native/android
TERMUX_PKG_DESCRIPTION="Stub libandroid.so needed on Termux Docker"
TERMUX_PKG_LICENSE="NCSA"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=26
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r${TERMUX_PKG_VERSION}-linux.zip
TERMUX_PKG_SHA256=1505c2297a5b7a04ed20b5d44da5665e91bac2b7c0fbcd3ae99b6ccc3a61289a
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_make_install() {
	install -v -Dm644 \
		"toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TERMUX_HOST_PLATFORM/$TERMUX_PKG_API_LEVEL/libandroid.so" \
		"$TERMUX_PREFIX/lib/libandroid.so"
}

termux_step_create_debscripts() {
	# If the system has the real `libandroid.so` already, then use it, to
	# allow installing this package in a "normal" Android system mistakenly.
	local _BITS=""
	if [ "$TERMUX_ARCH_BITS" = 64 ]; then _BITS=64; fi
	cat <<- EOF > postinst
	#!$TERMUX_PREFIX/bin/sh
	if [ -e /system/lib${_BITS}/libandroid.so ]; then
	echo "Symlink /system/lib${_BITS}/libandroid.so to $TERMUX_PREFIX/lib/libandroid.so ..."
	ln -fsT "/system/lib${_BITS}/libandroid.so" "$TERMUX_PREFIX/lib/libandroid.so"
	fi
	EOF

	cat <<- EOF > postrm
	#!$TERMUX_PREFIX/bin/sh
	rm -f "$TERMUX_PREFIX/lib/libandroid.so"
	EOF
}
