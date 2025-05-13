# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi optfeature

DESCRIPTION="Authentication and Registration in Django Rest Framework"
HOMEPAGE="
	https://pypi.org/project/dj-rest-auth/
	http://github.com/iMerica/dj-rest-auth
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/django
	dev-python/djangorestframework
	dev-python/django-allauth
"
BDEPEND="
	test? (
		dev-python/coveralls
		dev-python/django-allauth
		dev-python/djangorestframework-simplejwt
		dev-python/responses
		dev-python/unittest-xml-reporting
	)
"

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "Social authentication" "dev-python/django-allauth"
}
