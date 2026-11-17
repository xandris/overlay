# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13..14} )

inherit distutils-r1 pypi

DESCRIPTION="A python binding for FFmpeg which provides sync and async APIs"
HOMEPAGE="
	https://pypi.org/project/python-ffmpeg/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/pyee
	dev-python/typing-extensions
"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest
