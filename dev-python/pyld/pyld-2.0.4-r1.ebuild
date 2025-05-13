# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )
PYPI_PN=PyLD
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi optfeature

DESCRIPTION="Python implementation of the JSON-LD API"
HOMEPAGE="
	https://pypi.org/project/PyLD/
	https://github.com/digitalbazaar/pyld/
"

LICENSE=""
SLOT="0"
KEYWORDS="~arm64 ~amd64"

RDEPEND="
	dev-python/cachetools
	dev-python/frozendict
	dev-python/lxml
"
BDEPEND=""

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "Document loading via requests" "dev-python/requests"
	optfeature "Document loading via aiohttp" "dev-python/aiohttp"
}
