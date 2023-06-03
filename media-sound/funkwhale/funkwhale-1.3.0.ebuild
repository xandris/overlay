# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Federated audio server."
HOMEPAGE="https://funkwhale.audio/"
SRC_URI="https://dev.funkwhale.audio/${PN}/${PN}/-/archive/${PV}/${P}.tar.bz2"
RESTRICT="mirror network-sandbox"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm"
IUSE="system-python ldap"

PATCHES=(
	"${FILESDIR}/${PN}-server-path-notify.patch"
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
		=dev-python/click-7.1*
		=dev-python/django-3.2*
		=dev-python/django-cacheops-6.0*
		=dev-python/django-redis-5.0*
		=dev-python/djangorestframework-3.12*
		=dev-python/feedparser-6.0*
		=dev-python/markdown-3.3*
		=dev-python/python-magic-0.4*
		=dev-python/python-musicbrainzngs-0.7*
		=dev-python/pyopenssl-22.0*
		=dev-python/service_identity-21.1*
		>=dev-python/setuptools-57
		=dev-python/watchdog-2.1*

		=media-libs/mutagen-1.45*
		=www-servers/gunicorn-20.1*
	)

	ldap? (
		dev-libs/cyrus-sasl:2
		net-nds/openldap

		system-python? (
			=dev-python/django-auth-ldap-3.0*
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
	local pip
	local pip_args=( -v --no-compile )
	local -x POETRY_VIRTUALENVS_IN_PROJECT=true
	local -x POETRY_VIRTUALENVS_OPTIONS_NO_PIP=true
	local -x POETRY_VIRTUALENVS_OPTIONS_NO_SETUPTOOLS=true
	if use system-python; then
		local -x POETRY_VIRTUALENVS_OPTIONS_SYSTEM_SITE_PACKAGES=true
	fi
	local -x POETRY_INSTALLER_NO_BINARY=pillow,uvloop,watchfiles,yarl,lxml,cryptography,wrapt,msgpack,websockets,msgpack,pvectorc,multidict,frozenlist,zope,cffi

	einfo "EPYTHON: ${EPYTHON}"
	einfo "PYTHON: ${PYTHON}"

	einfo "Setting up virtualenv"
	"${EPYTHON}" -m venv build-venv

	pip=build-venv/bin/pip

	einfo "Upgrading pip in virtualenv"
	"$pip" install "${pip_args[@]}" --upgrade pip || die "Failed to upgrade pip"

	einfo "Installing 'poetry' into virtualenv"
	"$pip" install "${pip_args[@]}" poetry || die "Failed to install python package 'poetry'"

	build-venv/bin/poetry install -C api --without dev || die "Failed to install $PN dependencies"

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

	insinto "${top}"/config
	doins "deploy/env.prod.sample"

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
