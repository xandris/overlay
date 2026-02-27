# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="Deletes old files."
HOMEPAGE="
	https://pypi.org/project/django-cleanup/
	https://github.com/un1t/django-cleanup/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND=">=dev-python/django-3.2"
BDEPEND=""

distutils_enable_tests pytest
