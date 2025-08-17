# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="Django apps addressing authentication, registration, account management."
HOMEPAGE="
	https://pypi.org/project/django-allauth/
	https://www.intenct.nl/projects/django-allauth/
	https://github.com/pennersr/django-allauth
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/django
	dev-python/python3-openid
	dev-python/requests-oauthlib
	dev-python/requests
	dev-python/pyjwt
	dev-python/cryptography
"
BDEPEND="
	test? (
		dev-python/pillow
	)
"

distutils_enable_tests pytest
