# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Federated audio server."
HOMEPAGE="https://funkwhale.audio/"
SRC_URI="https://dev.funkwhale.audio/${PN}/${PN}/-/archive/${PV}/${P}.tar.bz2"
RESTRICT="mirror network-sandbox"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~arm64"
IUSE="system-python ldap"

PATCHES=(
	"${FILESDIR}/${PN}-server-path-notify.patch"
	"${FILESDIR}/${PN}-systemd-tweaks.patch"
	"${FILESDIR}/${P}-subsonic-various-artists-hack.patch"
)

# Compile-time only dependencies
# Including libraries needed to 'pip install' but optional at runtime.
DEPEND="
	dev-db/postgresql
	dev-db/redis

	dev-libs/libxml2
	dev-libs/libxslt

	sys-libs/zlib

	virtual/jpeg

	system-python? (
		=dev-python/django-3*
		=dev-python/django-cacheops-7*
		=dev-python/django-cors-headers-4*
		=dev-python/django-filter-23*
		=dev-python/django-redis-5*
		=dev-python/djangorestframework-3*
		=dev-python/markdown-3*
		dev-python/psycopg:2
		=dev-python/redis-4*
		=dev-python/kombu-5*
		=dev-python/celery-5*
		=www-servers/gunicorn-20*
		=dev-python/uvicorn-0.20*
		=dev-python/aiohttp-3*
		=dev-python/arrow-1*
		=dev-python/bleach-6*
		=dev-python/boto3-1*
		=dev-python/click-8*
		=dev-python/cryptography-40*
		=dev-python/feedparser-6*
		=dev-python/python-musicbrainzngs-0.7*
		=media-libs/mutagen-1*
		=dev-python/pillow-9*
		=dev-python/pydub-0.25*
		=dev-python/python-magic-0.4*
		dev-python/pytz
		=dev-python/watchdog-3*
		=dev-python/requests-2*
		=dev-python/sentry-sdk-1*
		=dev-python/importlib-metadata-6*
	)

	ldap? (
		dev-libs/cyrus-sasl:2
		net-nds/openldap

		system-python? (
			=dev-python/django-auth-ldap-4*
			=dev-python/python-ldap-5*
		)
	)
"

RDEPEND="${DEPEND}

	acct-user/funkwhale
	acct-group/funkwhale
"

BDEPEND="
	dev-vcs/git

	net-libs/nodejs

	sys-apps/yarn
	sys-devel/make

	virtual/rust
"

PYTHON_COMPAT=( python3_9 python3_10 python3_11 pypy3 )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_SETUPTOOLS=no

inherit distutils-r1 systemd multiprocessing

src_prepare() {
	if ! use ldap; then
		eapply "${FILESDIR}/${P}-disable-ldap.patch"
	fi

	if use system-python; then
		# Allow semver upgrades to boost chances of finding matching packages
		sed -Ei '/^version = "/! s/"(==)?([0-9]+\.)/"^\2/' api/pyproject.toml
		# Except for django_auth_toolkit. 2.3.0 needs a new migration.
		# Funkwhale disables its migrations and must handle them manually.
		# USE flag should not affect database structure, so we don't apply
		# it ourselves.
		sed -Ei '/^django-oauth-toolkit[ =]/ s/"\^/"~/' api/pyproject.toml
		rm api/poetry.lock
		eapply "${FILESDIR}/${P}-aggressive-python-updates.patch"
	fi

	default
}

get-pypy-libdir() {
	local i
	for i in "${ESYSROOT}/usr/$(get_abi_LIBDIR)/pypy3."*; do
		if [[ -d "$i" ]]; then
			echo "$i"
			return
		fi
	done
	return 1
}


src_configure() {
	einfo "EPYTHON: ${EPYTHON}"
	einfo "PYTHON: ${PYTHON}"

	local -x POETRY_VIRTUALENVS_IN_PROJECT=true
	local pip_args=( -v --no-compile )
	if use system-python; then
		local -x POETRY_VIRTUALENVS_OPTIONS_SYSTEM_SITE_PACKAGES=true
		local -x POETRY_VIRTUALENVS_CREATE=false
		local -x VIRTUAL_ENV=venv

		einfo "Setting up virtualenv"
		"${EPYTHON}" -m venv venv --system-site-packages || die

		einfo "Installing 'poetry' into virtualenv"

		{
			venv/bin/pip install "${pip_args[@]}" poetry \
			&& venv/bin/poetry lock -C api \
			&& venv/bin/poetry show -C api --tree --only main \
			&& venv/bin/poetry export -C api -f requirements.txt --without-hashes --only main -o api/requirements.txt || die 'Failed to export dependencies as requirements.txt' \
			&& rm -r venv
		} || die 'Failed to turn Poetry dependencies into requirements.txt'

		einfo "Setting up virtualenv (again)"
		{
			"${EPYTHON}" -m venv api/.venv --system-site-packages \
			&& api/.venv/bin/pip install "${pip_args[@]}" -r api/requirements.txt \
			&& api/.venv/bin/pip uninstall pip setuptools -y
		}
	else
		local -x POETRY_INSTALLER_NO_BINARY=pillow,uvloop,watchfiles,yarl,lxml,cryptography,wrapt,msgpack,websockets,msgpack,pvectorc,multidict,frozenlist,zope,cffi
		local pip=build-venv/bin/pip

		if ! [[ -d build-venv ]]; then
			einfo "Setting up virtualenv"
			"${EPYTHON}" -m venv build-venv || die

			einfo "Installing 'poetry' into virtualenv"
			"$pip" install "${pip_args[@]}" poetry || die "Failed to install python package 'poetry'"
		fi

		build-venv/bin/poetry install -C api --without dev
	fi || die "Failed to install $PN dependencies"


	pushd front || die
	tc-env_build yarn --ignore-engines || die "Failed to install yarn packages"
	find node_modules/fomantic-ui-css -name '*.css' -print0 | xargs -0 sed -i 's/;;/;/g'
	popd || die
}

src_compile() {
	local -x NODE_ENV=production
	pushd front || die
	tc-env_build yarn run fix-fomantic-css
	tc-env_build yarn run build:deployment | tee /dev/stderr | (! grep -i 'ERROR in' ) || \
		die "Failed to build frontend"
	popd || die
}

src_install() {
	default

	local top="/srv/${PN}"
	local venv="${top}/venv"
	local py="${venv}/bin/python" 
	local fn
	local header
	local dest
	local apifiles=()

	diropts -o funkwhale -g funkwhale
	insopts -o funkwhale -g funkwhale

	insinto "${top}/frontend"
	doins -r front/dist/*

	insinto "${top}/api"
	for fn in api/*; do
		if [[ $fn == api/.venv ]]; then
			continue
		fi
		apifiles+=("$fn")
	done
	doins -r "${apifiles[@]}"

	insinto "${top}/venv"
	doins -r api/.venv/*

	newdoc "deploy/env.prod.sample" conf.d-funkwhale.sample

	newbin "${FILESDIR}/funkwhale-1.3.0" funkwhale

	systemd_dounit deploy/*.service deploy/*.target

	keepdir "${top}"/data/{media,static,music}

	for fn in api/.venv/lib/*/site-packages/funkwhale_api.pth; do
		if ! [[ -f $fn ]]; then
			continue
		fi
		dest="${venv}/${fn#api/.venv/}"
		insinto "${dest%/*}"
		newins - funkwhale_api.pth <<<"${top}/api"
	done

	insinto "${venv}/bin"
	insopts -m755
	while read -r fn; do
		read -rN 2 header < "${fn}"
		if [[ ${header} == '#!' ]]; then
			awk -v PY="${py}" 'NR==1 { printf("#!%s\n", PY) } NR>1 { print }' "${fn}" \
			| newins - "${fn##*/}" || die "Failed to tweak shebang for ${dest#${ED}}"
		fi
	done < <( find api/.venv/bin -maxdepth 1 -type f ) || die "Failed to tweak shebangs"

	python_optimize "${ED}/${venv#/}/lib" "${ED}/${top#/}/api" || die "Failed to optimize Python packages"
}
