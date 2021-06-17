# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{8..10} )
inherit autotools python-any-r1

DESCRIPTION="Cockpit is a web-based graphical interface for servers."
HOMEPAGE="https://cockpit-project.org/"
SRC_URI="https://github.com/${PN}-project/${PN}/releases/download/${PV}/${P}.tar.xz"
RESTRICT="mirror"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="asan debug doc go pam pcp polkit ssh"
DEPEND="
	acct-user/${PN}
	acct-group/${PN}
	pcp? ( app-admin/pcp )
	polkit? ( sys-auth/polkit )
	ssh? ( >=net-libs/libssh-0.8.5[server] )
	app-arch/lz4
	app-arch/zstd
	>=app-crypt/mit-krb5-1.11
	app-crypt/p11-kit
	dev-libs/glib
	dev-libs/gmp
	dev-libs/json-glib
	dev-libs/libffi
	dev-libs/libgcrypt
	dev-libs/libgpg-error
	dev-libs/libpcre
	dev-libs/libtasn1
	dev-libs/libunistring
	dev-libs/nettle
	dev-libs/openssl
	net-dns/libidn2
	net-libs/gnutls
	sys-apps/keyutils
	sys-apps/systemd
	sys-libs/e2fsprogs-libs
	sys-libs/libcap
	sys-libs/pam
	sys-libs/zlib
"
RDEPEND="${DEPEND}
	pam? ( sys-libs/pam )
	sys-apps/kexec-tools
	sys-fs/udisks
	$(python_gen_any_dep '
		dev-python/dbus-python[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	doc? (
		app-text/xmlto
		dev-libs/libxslt
		media-gfx/inkscape
	)
	go? ( dev-lang/go )
	sys-devel/gettext
	virtual/pkgconfig
	${PYTHON_DEPS}
"
# One day maybe we can build from the source tarball...
# The makefile wants to know the SHA-1 of the node_modules directory
# so it can cache dependencies in ~/.cache/cockpit-dev.
# But I don't have that directory so shrug?
#net-libs/nodejs

src_configure() {
	local myconf="
		$(use_enable asan)
		$(use_enable debug)
		$(use_enable doc)
		$(use_enable pcp)
		$(use_enable polkit)
		$(use_enable ssh)
		--with-cockpit-user=cockpit
		--with-cockpit-group=cockpit
		--with-cockpit-ws-instance-user=cockpit
		--with-cockpit-ws-instance-group=cockpit
		--with-admin-group=wheel
	"
	econf $myconf
}

src_install() {
	default
	if use pam; then
		install -d -m 755 "${ED}/etc/pam.d"
		cp "${FILESDIR}/cockpit.pam" "${ED}/etc/pam.d/cockpit"
	fi
}
