# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{12,11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Registries that can autodiscover values accross your project apps"
HOMEPAGE="
	https://pypi.org/project/persisting-theory/
	https://code.agate.blue/agate/persisting-theory/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND=""
BDEPEND=""
PATCHES=( "${FILESDIR}/${PN}-fix-stray-files.patch" )

distutils_enable_tests pytest
