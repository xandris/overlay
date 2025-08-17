# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="Django ASGI (HTTP/WebSocket) server"
HOMEPAGE="
	https://pypi.org/project/daphne/
	https://github.com/django/daphne
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	>=dev-python/asgiref-3.5.2
	<dev-python/asgiref-4
	>=dev-python/autobahn-22.4.2
	>=dev-python/twisted-22.4[ssl]
"
BDEPEND="
	test? (
		dev-python/django
		dev-python/hypothesis
		dev-python/pytest
		dev-python/pytest-asyncio
	)
"

distutils_enable_tests pytest
