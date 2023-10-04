TERMUX_PKG_HOMEPAGE=https://developer.android.com/tools/sdk/ndk/index.html
TERMUX_PKG_DESCRIPTION="Multilib binaries for cross-compilation"
TERMUX_PKG_LICENSE="NCSA"
TERMUX_PKG_MAINTAINER="@termux"
# Version should be equal to TERMUX_NDK_{VERSION_NUM,REVISION} in
# scripts/properties.sh
TERMUX_PKG_VERSION=26
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r${TERMUX_PKG_VERSION}-linux.zip
TERMUX_PKG_SHA256=1505c2297a5b7a04ed20b5d44da5665e91bac2b7c0fbcd3ae99b6ccc3a61289a
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_get_source() {
	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		termux_download_src_archive
		cd $TERMUX_PKG_TMPDIR
		termux_extract_src_archive
	fi
	mkdir -p $TERMUX_PKG_SRCDIR
}

prepare_libs() {
	local ARCH="$1"
	local SUFFIX="$2"

	local _ndk_prefix

	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		_ndk_prefix="$TERMUX_PKG_SRCDIR"
	else
		_ndk_prefix="$NDK"
	fi

	mkdir -p $TERMUX_PREFIX/$SUFFIX/lib
	mkdir -p $TERMUX_PREFIX/opt/ndk-multilib/$SUFFIX/lib
	local BASEDIR=$_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$SUFFIX/
	cp $BASEDIR/${TERMUX_PKG_API_LEVEL}/*.o $TERMUX_PREFIX/$SUFFIX/lib
	cp $BASEDIR/${TERMUX_PKG_API_LEVEL}/lib{c,dl,log,m}.so $TERMUX_PREFIX/opt/ndk-multilib/$SUFFIX/lib
	cp $BASEDIR/libc++_shared.so $TERMUX_PREFIX/$SUFFIX/lib
	cp $BASEDIR/lib{c,dl,m}.a $TERMUX_PREFIX/opt/ndk-multilib/$SUFFIX/lib
	cp $BASEDIR/lib{c++_static,c++abi}.a $TERMUX_PREFIX/$SUFFIX/lib
	echo 'INPUT(-lc++_static -lc++abi)' > $TERMUX_PREFIX/$SUFFIX/lib/libc++_shared.a

	local f
	for f in lib{c,dl,log,m}.so lib{c,dl,m}.a; do
		ln -sfT $TERMUX_PREFIX/opt/ndk-multilib/$SUFFIX/lib/${f} \
			$TERMUX_PREFIX/$SUFFIX/lib/${f}
	done

	NDK_ARCH=$TERMUX_ARCH
	test $NDK_ARCH == 'i686' && NDK_ARCH='i386'

	cp $_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/*/lib/linux/$NDK_ARCH/libatomic.a \
		$TERMUX_PREFIX/$SUFFIX/lib/
	cp $_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/*/lib/linux/$NDK_ARCH/libunwind.a \
		$TERMUX_PREFIX/$SUFFIX/lib/
}

add_cross_compiler_rt() {
	local _ndk_prefix

	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		_ndk_prefix="$TERMUX_PKG_SRCDIR"
	else
		_ndk_prefix="$NDK"
	fi

	RT_PREFIX=$_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/*/lib/linux
	RT_OPT_DIR=$TERMUX_PREFIX/opt/ndk-multilib/cross-compiler-rt
	mkdir -p $RT_OPT_DIR
	cp $RT_PREFIX/* $RT_OPT_DIR || true
}

termux_step_make_install() {
	prepare_libs "arm" "arm-linux-androideabi"
	prepare_libs "aarch64" "aarch64-linux-android"
	prepare_libs "i686" "i686-linux-android"
	prepare_libs "x86_64" "x86_64-linux-android"
	add_cross_compiler_rt
}

termux_step_post_massage() {
	local triple f
	for triple in aarch64-linux-android arm-linux-androideabi i686-linux-android x86_64-linux-android; do
		for f in lib{c,dl,log,m}.so lib{c,dl,m}.a; do
			rm -f ${triple}/lib/${f}
		done
	done
}

termux_step_create_debscripts() {
	local f
	for f in postinst prerm; do
		sed -e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
			-e "s|@TERMUX_PACKAGE_FORMAT@|${TERMUX_PACKAGE_FORMAT}|g" \
			$TERMUX_PKG_BUILDER_DIR/postinst-header.in > "${f}"
	done
	sed 's|@COMMAND@|ln -sf "'$TERMUX_PREFIX'/opt/ndk-multilib/$triple/lib/$so" "'$TERMUX_PREFIX'/\$triple/lib"|' \
		$TERMUX_PKG_BUILDER_DIR/postinst-alien.in >> postinst
	sed 's|@COMMAND@|rm -f "'$TERMUX_PREFIX'/$triple/lib/$so"|' \
		$TERMUX_PKG_BUILDER_DIR/postinst-alien.in >> prerm
	chmod 0700 postinst prerm
}
