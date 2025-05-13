# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13,12} )

inherit distutils-r1 pypi

DESCRIPTION="Data about countries, ISO info and states/provinces within them"
HOMEPAGE="https://pypi.org/project/countryinfo/"
RESTRICT="mirror"
commit="e90277480434ee194fd71c3f324ea09ee0e6570d"
SRC_URI="
	https://github.com/porimol/countryinfo//archive/${commit}.tar.gz -> ${P}.tar.gz
"
S="${WORKDIR}/countryinfo-${commit}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests pytest
