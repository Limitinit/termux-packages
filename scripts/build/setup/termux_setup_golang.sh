# Utility function for golang-using packages to setup a go toolchain.
termux_setup_golang() {
	if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
		local TERMUX_GO_VERSION=go1.21.2
		local TERMUX_GO_SHA256=f5414a770e5e11c6e9674d4cd4dd1f4f630e176d1828d3427ea8ca4211eee90d
		if [ "$TERMUX_PKG_GO_USE_OLDER" = "true" ]; then
			TERMUX_GO_VERSION=go1.20.9
			TERMUX_GO_SHA256=8921369701afa749b07232d2c34d514510c32dbfd79c65adb379451b5f0d7216
		fi
		local TERMUX_GO_PLATFORM=linux-amd64

		local TERMUX_BUILDGO_FOLDER
		if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
			TERMUX_BUILDGO_FOLDER=${TERMUX_SCRIPTDIR}/build-tools/${TERMUX_GO_VERSION}
		else
			TERMUX_BUILDGO_FOLDER=${TERMUX_COMMON_CACHEDIR}/${TERMUX_GO_VERSION}
		fi

		export GOROOT=$TERMUX_BUILDGO_FOLDER
		export PATH=${GOROOT}/bin:${PATH}

		if [ -d "$TERMUX_BUILDGO_FOLDER" ]; then return; fi

		local TERMUX_BUILDGO_TAR=$TERMUX_COMMON_CACHEDIR/${TERMUX_GO_VERSION}.${TERMUX_GO_PLATFORM}.tar.gz
		rm -Rf "$TERMUX_COMMON_CACHEDIR/go" "$TERMUX_BUILDGO_FOLDER"
		termux_download https://golang.org/dl/${TERMUX_GO_VERSION}.${TERMUX_GO_PLATFORM}.tar.gz \
			"$TERMUX_BUILDGO_TAR" \
			"$TERMUX_GO_SHA256"

		( cd "$TERMUX_COMMON_CACHEDIR"; tar xf "$TERMUX_BUILDGO_TAR"; mv go "$TERMUX_BUILDGO_FOLDER"; rm "$TERMUX_BUILDGO_TAR" )

		if [ "$TERMUX_PKG_GO_USE_OLDER" = "false" ]; then
			( cd "$TERMUX_BUILDGO_FOLDER"; . ${TERMUX_SCRIPTDIR}/packages/golang/fix-hardcoded-etc-resolv-conf.sh )
		fi
	else
		if [[ "$TERMUX_APP_PACKAGE_MANAGER" = "apt" && "$(dpkg-query -W -f '${db:Status-Status}\n' golang 2>/dev/null)" != "installed" ]] ||
		   [[ "$TERMUX_APP_PACKAGE_MANAGER" = "pacman" && ! "$(pacman -Q golang 2>/dev/null)" ]]; then
			echo "Package 'golang' is not installed."
			echo "You can install it with"
			echo
			echo "  pkg install golang"
			echo
			echo "  pacman -S golang"
			echo
			echo "or build it from source with"
			echo
			echo "  ./build-package.sh golang"
			echo
			exit 1
		fi

		export GOROOT="$TERMUX_PREFIX/lib/go"
	fi
}
