# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13..14} )

inherit distutils-r1 pypi

DESCRIPTION=""
HOMEPAGE="
	https://pypi.org/project/channels-redis/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/django[${PYTHON_USEDEP}]
		dev-python/asgiref[${PYTHON_USEDEP}]
	')
"
BDEPEND=""

EPYTEST_PLUGINS=()
distutils_enable_tests pytest
