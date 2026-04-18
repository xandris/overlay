# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )
RESTRICT="mirror"

inherit distutils-r1 pypi

DESCRIPTION="Client for Typesense"
HOMEPAGE="
	https://pypi.org/project/typesense/
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	>=dev-python/requests-2.22.0
"
