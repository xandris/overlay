# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_12 python3_11 )

inherit distutils-r1 pypi

DESCRIPTION="ListenBrainz' empathic music recommendation/playlisting engine"
HOMEPAGE="
	https://pypi.org/project/troi-recommendation-playground/
"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	>=dev-python/click-8.0
	>=dev-python/countryinfo-0.1.2
	>=dev-python/lb-matching-tools-2024.01.30.1
	>=dev-python/liblistenbrainz-0.5.5
	dev-python/more-itertools
	>=media-libs/mutagen-1.46.0
	>=dev-python/peewee-3.17.0
	>=dev-python/psycopg-2.9.3:2
	>=dev-python/py-sonic-1.0.0
	>=dev-python/python-dateutil-2.8.2
	>=dev-python/regex-2023.6.3
	>=dev-python/requests-2.31.0
	>=dev-python/scikit-learn-1.2.1
	>=dev-python/spotipy-2.22.1
	dev-python/tqdm
	>=dev-python/ujson-4.5.0
	>=dev-python/unidecode-1.3.6
"

BDEPEND="
	test? (
		dev-python/pytest-cov
		dev-python/requests-mock
	)
"

distutils_enable_tests pytest

distutils_enable_sphinx docs \
		dev-python/sphinxcontrib-httpdomain \
		dev-python/sphinx-rtd-theme \
		dev-python/docutils \
		dev-python/sphinx-click
