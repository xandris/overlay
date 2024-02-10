# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_12 python3_11 )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="A python wrapper library for the Subsonic REST API."
HOMEPAGE="
	https://pypi.org/project/py-sonic/
"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
