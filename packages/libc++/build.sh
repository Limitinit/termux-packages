TERMUX_PKG_HOMEPAGE=https://libcxx.llvm.org/
TERMUX_PKG_DESCRIPTION="C++ Standard Library"
TERMUX_PKG_LICENSE="NCSA"
TERMUX_PKG_MAINTAINER="@termux"
# Version should be equal to TERMUX_NDK_{VERSION_NUM,REVISION} in
# scripts/properties.sh
TERMUX_PKG_VERSION=26
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r${TERMUX_PKG_VERSION}-linux.zip
TERMUX_PKG_SHA256=1505c2297a5b7a04ed20b5d44da5665e91bac2b7c0fbcd3ae99b6ccc3a61289a
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_get_source() {
	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		termux_download_src_archive
		cd $TERMUX_PKG_TMPDIR
		termux_extract_src_archive
	fi
	mkdir -p $TERMUX_PKG_SRCDIR
}

termux_step_post_make_install() {
	local _ndk_prefix

	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		_ndk_prefix="$TERMUX_PKG_SRCDIR"
	else
		_ndk_prefix="$NDK"
	fi

	install -m700 -t "$TERMUX_PREFIX"/lib \
		$_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/"${TERMUX_HOST_PLATFORM}"/libc++_shared.so
}
