# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="Django utility for a memoization decorator that uses the Django cache framework."
HOMEPAGE="
	https://pypi.org/project/django-cache-memoize/
	https://github.com/peterbe/django-cache-memoize/
"

LICENSE="MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND=""
BDEPEND=""

distutils_enable_tests pytest
