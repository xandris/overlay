# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{8..10} )
inherit autotools python-any-r1

DESCRIPTION="Performance Co-Pilot is a system performance analysis toolkit."
HOMEPAGE="https://pcp.io/"
SRC_URI="https://github.com/performancecopilot/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="discovery infiniband libpfm lz4 man python qt qt3d rpm sasl selinux statsd systemd systemtap +threads podman X zlib zstd"
DEPEND="
	discovery? ( net-dns/avahi )
	libpfm? ( dev-libs/libpfm )
	lz4? ( app-arch/lz4 )
	python? ( $(python_gen_any_dep '
		dev-python/jsonpointer[${PYTHON_USEDEP}]
		dev-python/setuptools[${PYTHON_USEDEP}]
		dev-python/six[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/openpyxl[${PYTHON_USEDEP}]
	') )
	qt? (
		dev-qt/qtchooser
		dev-qt/qtcore:5
	)
	qt3d? (
		dev-qt/qt3d
		dev-games/openscenegraph-qt
		media-libs/SoQt
		media-libs/coin
	)
	rpm? (
		app-arch/rpm
	)
	sasl? (
		dev-libs/cyrus-sasl
		dev-libs/nss
	)
	systemd? ( sys-apps/systemd )
	systemtap? ( dev-util/systemtap )
	podman? ( dev-libs/libvarlink )
	X? ( x11-libs/libXt )
	zlib? ( sys-libs/zlib )
	zstd? ( app-arch/zstd )
	acct-group/pcp
	acct-user/pcp
	dev-libs/cyrus-sasl
	dev-libs/libgcrypt
	dev-libs/libgpg-error
	dev-libs/libuv
	dev-libs/libuv
	dev-libs/nspr
	dev-libs/openssl
	sys-libs/libcap
	sys-libs/ncurses
	sys-libs/readline
"

RDEPEND="${DEPEND}"

BDEPEND="
	app-arch/zip
	statsd? ( dev-util/ragel )
	sys-apps/coreutils
	sys-devel/bison
	sys-devel/flex
	X? ( x11-misc/makedepend )
"

PATCHES=(
	"${FILESDIR}/${PN}-fix-without-static-probes.patch"
	"${FILESDIR}/${PN}-fix-ar-check.patch"
)

src_prepare() {
	default
	eautoreconf
	sed -Ei '/HAVE_64|PM_SIZEOF/ d' src/include/pcp/config.h.in
}

src_configure() {
	local myconf="
		--localstatedir=/var
		--without-python
		$(use_with discovery)
		$(use_with infiniband)
		$(use_with python python3)
		$(use_with qt)
		$(use_with qt3d)
		$(use_with sasl secure-sockets)
		$(use_with selinux)
		$(use_with systemd)
		$(use_with systemtap static-probes)
		$(use_with threads)
		$(use_with X x)
		$(use_with podman pmdapodman)
		$(use_with statsd pmdastatsd)
		$(use_with libpfm perfevent)
	"
	econf $myconf
# Their makefile will look for these directories.
# If present, they'll end up installing the testsuite.
# They're safe to remove though, and those parts won't
# be built.
	local prune=( build debian qa )
	if ! use man; then
		prune+=( man )
	fi
	rm -r "${prune[@]}"
}

src_install() {
	DIST_ROOT=${D} emake -j1 install
	dodoc CHANGELOG README.md
}
