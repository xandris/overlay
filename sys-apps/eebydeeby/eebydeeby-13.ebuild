# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Eebydeeby janky automated Gentoo custodian"
HOMEPAGE="https://github.com/xandris/eebydeeby"
SRC_URI="https://github.com/xandris/${PN}/archive/${PV}/${P}.tar.gz"
RESTRICT="mirror"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="virtual/linux-sources"
RDEPEND="
	app-admin/eclean-kernel
	app-admin/needrestart
	app-portage/eix
	app-portage/gentoolkit
	>=app-shells/bash-4
	dev-python/ansi2html
	sys-apps/systemd
	sys-apps/util-linux
	sys-kernel/dracut
	virtual/mta
"
