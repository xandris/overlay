# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="ListenBrainz tools for matching metadata to and from MusicBrainz."
HOMEPAGE="
	https://pypi.org/project/lb-matching-tools/
"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	dev-python/regex
"
BDEPEND="
	test? (
		dev-python/pytest-cov
	)
"

distutils_enable_tests pytest
