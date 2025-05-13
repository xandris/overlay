# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_13 )

inherit distutils-r1 pypi optfeature

DESCRIPTION="Python implementation of the JSON-LD API"
HOMEPAGE="
	https://pypi.org/project/audioop-lts
	https://github.com/AbstractUmbra/audioop
"

LICENSE=""
SLOT="0"
KEYWORDS="~arm64 ~amd64"

RDEPEND=""
BDEPEND=""

distutils_enable_tests pytest
