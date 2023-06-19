# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Dynamic global and instance settings for your django project"
HOMEPAGE="
	https://pypi.org/project/django-dynamic-preferences/
	https://github.com/agateblue/django-dynamic-preferences/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	>=dev-python/django-3.2
	dev-python/six
	=dev-python/persisting-theory-1.0
"
BDEPEND=""

distutils_enable_tests pytest
