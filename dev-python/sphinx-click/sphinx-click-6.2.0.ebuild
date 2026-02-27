# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{14,13,12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 pypi

DESCRIPTION="Sphinx plugin to automatically document click-based applications"
HOMEPAGE="
	https://github.com/click-contrib/sphinx-click
	https://pypi.org/project/sphinx-click/
"

LICENSE="MIT"
KEYWORDS="~amd64"
SLOT="0"

RDEPEND="
	>=dev-python/sphinx-2.0[${PYTHON_USEDEP}]
	>=dev-python/click-7.0[${PYTHON_USEDEP}]
	dev-python/docutils[${PYTHON_USEDEP}]
"
BDEPEND="dev-python/build[${PYTHON_USEDEP}]"

distutils_enable_tests pytest
distutils_enable_sphinx docs --no-autodoc
