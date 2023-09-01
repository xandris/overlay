# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{12,11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Flexible, extensible drop-in replacement for django's ImageField."
HOMEPAGE="
	https://pypi.org/project/django-versatileimagefield/
	https://github.com/respondcreate/django-versatileimagefield/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/django
	dev-python/pillow
	dev-python/python-magic
"
BDEPEND=""

PATCHES=(
	"${FILESDIR}/${P}-pillow-10-compat.patch"
)

distutils_enable_tests pytest
