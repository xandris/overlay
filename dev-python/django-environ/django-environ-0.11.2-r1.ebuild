# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="12factor inspired environment variables to configure Django."
HOMEPAGE="
	https://pypi.org/project/django-environ/
	https://django-environ.readthedocs.org/
	https://github.com/joke2k/django-environ/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND=""
BDEPEND=""

distutils_enable_sphinx docs \
	dev-python/furo \
	dev-python/sphinx \
	dev-python/sphinx-notfound-page
distutils_enable_tests pytest
