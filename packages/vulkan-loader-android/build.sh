TERMUX_PKG_HOMEPAGE=https://source.android.com/devices/graphics/arch-vulkan
TERMUX_PKG_DESCRIPTION="Vulkan Loader for Android"
TERMUX_PKG_LICENSE="NCSA"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=26
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r${TERMUX_PKG_VERSION}-linux.zip
TERMUX_PKG_SHA256=1505c2297a5b7a04ed20b5d44da5665e91bac2b7c0fbcd3ae99b6ccc3a61289a
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_BUILD_IN_SRC=true

# Desktop Vulkan Loader
# https://github.com/KhronosGroup/Vulkan-Loader
# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/LoaderAndLayerInterface.md

# Android Vulkan Loader
# https://android.googlesource.com/platform/frameworks/native/+/master/vulkan
# https://android.googlesource.com/platform/frameworks/native/+/master/vulkan/libvulkan/libvulkan.map.txt

termux_step_get_source() {
	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		termux_download_src_archive
		cd $TERMUX_PKG_TMPDIR
		termux_extract_src_archive
	fi
	mkdir -p $TERMUX_PKG_SRCDIR
}

termux_step_host_build() {
	local _ndk_prefix

	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		_ndk_prefix="$TERMUX_PKG_SRCDIR"
	else
		_ndk_prefix="$NDK"
	fi

	# Use NDK provided vulkan header version
	# instead of vulkan-loader-generic vulkan.pc
	# https://github.com/android/ndk/issues/1721
	cat <<- EOF > vulkan_header_version.c
	#include <stdio.h>
	#include "vulkan/vulkan_core.h"
	int main(void) {
		printf("%d.%d.%d\n",
			VK_HEADER_VERSION_COMPLETE >> 22,
			VK_HEADER_VERSION_COMPLETE >> 12 & 0x03ff,
			VK_HEADER_VERSION_COMPLETE & 0x0fff);
		return 0;
	}
	EOF
	rm -fr ./vulkan
	cp -fr "$_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/vulkan" ./vulkan
	cc vulkan_header_version.c -o vulkan_header_version
}

termux_step_post_make_install() {
	local _ndk_prefix

	if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		_ndk_prefix="$TERMUX_PKG_SRCDIR"
	else
		_ndk_prefix="$NDK"
	fi

	install -v -Dm644 \
		"$_ndk_prefix/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${TERMUX_HOST_PLATFORM}/${TERMUX_PKG_API_LEVEL}/libvulkan.so" \
		"${TERMUX_PREFIX}/lib/libvulkan.so"

	local vulkan_loader_version
	vulkan_loader_version="$(${TERMUX_PKG_HOSTBUILD_DIR}/vulkan_header_version)"
	if [[ -z "${vulkan_loader_version}" ]]; then
		termux_error_exit "ERROR: Host built vulkan_header_version is not printing version!"
	fi

	# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/vulkan.pc.in
	cat <<- EOF > "${TERMUX_PKG_TMPDIR}/vulkan.pc"
	prefix=${TERMUX_PREFIX}
	exec_prefix=\${prefix}
	libdir=\${exec_prefix}/lib
	includedir=\${prefix}/include
	Name: Vulkan-Loader
	Description: Vulkan Loader
	Version: ${vulkan_loader_version}
	Libs: -L\${libdir} -lvulkan
	Cflags: -I\${includedir}
	EOF
	install -Dm644 "${TERMUX_PKG_TMPDIR}/vulkan.pc" "${TERMUX_PREFIX}/lib/pkgconfig/vulkan.pc"
	echo "INFO: ========== vulkan.pc =========="
	cat "${TERMUX_PREFIX}/lib/pkgconfig/vulkan.pc"
	echo "INFO: ========== vulkan.pc =========="

	ln -fsv libvulkan.so "${TERMUX_PREFIX}/lib/libvulkan.so.1"
}

termux_step_create_debscripts() {
	local system_lib="/system/lib"
	[[ "${TERMUX_ARCH_BITS}" == "64" ]] && system_lib+="64"
	system_lib+="/libvulkan.so"
	local prefix_lib="${TERMUX_PREFIX}/lib/libvulkan.so"

	cat <<- EOF > postinst
	#!${TERMUX_PREFIX}/bin/sh
	if [ -e "${system_lib}" ]; then
	echo "Symlink ${system_lib} to ${prefix_lib} ..."
	ln -fsT "${system_lib}" "${prefix_lib}"
	fi
	EOF

	cat <<- EOF > postrm
	#!${TERMUX_PREFIX}/bin/sh
	rm -f "${prefix_lib}"
	EOF
}
