# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )
PYPI_NO_NORMALIZE=1
PYPI_VERSION=1.2.0

inherit distutils-r1 pypi

DESCRIPTION="Singularize or pluralize a given word using a pre-defined list of rules"
HOMEPAGE="
	https://pypi.org/project/pluralizer/
	https://github.com/weixu365/pluralizer-py/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND=""
BDEPEND=""

distutils_enable_tests pytest

src_compile() {
	local -x PYPI_VERSION="${PV}"
	distutils-r1_src_compile
}
