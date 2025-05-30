# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="OAuth2 Provider for Django"
HOMEPAGE="
	https://pypi.org/project/django-oauth-toolkit/
	https://github.com/jazzband/django-oauth-toolkit/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/django
	dev-python/requests
	dev-python/oauthlib
	dev-python/jwcrypto
"
BDEPEND=""

distutils_enable_tests pytest
