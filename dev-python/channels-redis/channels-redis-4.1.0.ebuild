# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="Redis-backed ASGI channel layer implementation"
HOMEPAGE="
	https://github.com/django/channels_redis/
	https://pypi.org/project/channels-redis/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	>=dev-python/redis-4.5.3
	=dev-python/msgpack-1*
	=dev-python/asgiref-3.2.10
	<dev-python/asgiref-4
	dev-python/channels
"
BDEPEND="
	test? (
		dev-python/async-timeout
		dev-python/pytest
		dev-python/pytest-asyncio
		dev-python/pytest-timeout
	)
"

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "HTTP and Websocket termination server" "dev-python/daphne"
	optfeature "Symmetric encryption" "dev-python/cryptography"
}
