# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( pypy3 python3_11 )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="A request authentication plugin implementing IETF HTTP Message Signatures"
HOMEPAGE="
	https://pypi.org/project/requests-http-message-signatures/
	https://dev.funkwhale.audio/funkwhale/requests-http-message-signatures
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/requests
	dev-python/cryptography
"
BDEPEND=""

distutils_enable_tests pytest
