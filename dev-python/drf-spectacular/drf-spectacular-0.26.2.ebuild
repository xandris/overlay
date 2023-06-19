# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{11,10} )
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi optfeature

DESCRIPTION="Sane and flexible OpenAPI 3 schema generation for Django REST framework"
HOMEPAGE="
	https://pypi.org/project/drf-spectacular/
	https://github.com/tfranzel/drf-spectacular/
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~sparc ~x86"

RDEPEND="
	dev-python/django
	dev-python/djangorestframework
	dev-python/uritemplate
	dev-python/pyyaml
	dev-python/jsonschema
	dev-python/inflection
	dev-python/typing-extensions
"
BDEPEND="test? (
	dev-python/pytest-django
	dev-python/mypy
	dev-python/django-stubs
	dev-python/djangorestframework-stubs
	dev-python/types-pyyaml
)"

distutils_enable_tests pytest


