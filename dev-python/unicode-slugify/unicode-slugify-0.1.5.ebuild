# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="A slug generator that turns strings into unicode slugs."
HOMEPAGE="
	https://pypi.org/project/unicode-slugify/
	https://github.com/mozilla/unicode-slugify/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/six
	dev-python/unidecode
"
BDEPEND=""

distutils_enable_tests pytest
