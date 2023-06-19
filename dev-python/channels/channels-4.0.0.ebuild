# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Brings async, event-driven capabilities to Django 3.2 and up."
HOMEPAGE="
	http://github.com/django/channels
	https://pypi.org/project/channels/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	>=dev-python/django-3.2
	>=dev-python/asgiref-3.5.0
	<dev-python/asgiref-4
"
BDEPEND="
	test? (
		dev-python/pytest
		dev-python/pytest-django
		dev-python/pytest-asyncio
	)
"

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "HTTP and Websocket termination server" "dev-python/daphne"
}
