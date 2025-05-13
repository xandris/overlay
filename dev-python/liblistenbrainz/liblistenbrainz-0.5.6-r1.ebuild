# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="A simple ListenBrainz client library for Python"
HOMEPAGE="
	https://pypi.org/project/liblistenbrainz/
"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	>=dev-python/requests-2.31.0
"
BDEPEND="
	test? (
		dev-python/pytest-cov
	)
"

distutils_enable_tests pytest
