# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{12,11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi optfeature

DESCRIPTION="OpenID support for modern servers and consumers."
HOMEPAGE="
	https://pypi.org/project/python3-openid/
	https://github.com/necaris/python3-openid
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/defusedxml
"
BDEPEND=""

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "PostgreSQL support" "dev-python/psycopg2"
	optfeature "MySWL/MariaDB support" "dev-python/mysql-connector-python"
}
