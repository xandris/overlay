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

DEPEND="
	acct-user/funkwhale
	acct-group/funkwhale
	dev-db/postgresql
	sys-devel/make
	sys-libs/zlib
	virtual/jpeg

	=dev-python/click-7.1*
	=dev-python/django-3.2*
	=dev-python/django-auth-ldap-3.0*
	=dev-python/django-cacheops-6.0*
	=dev-python/django-redis-5.0*
	=dev-python/djangorestframework-3.12*
	=dev-python/feedparser-6.0*
	=dev-python/markdown-3.3*
	=dev-python/python-magic-0.4*
	=dev-python/python-musicbrainzngs-0.7*
	=dev-python/pyopenssl-20.0*
	=dev-python/service_identity-21.1*
	>=dev-python/setuptools-57
	=dev-python/watchdog-2.1*

	=media-libs/mutagen-1.45*

	=www-servers/gunicorn-20.1*
"

RDEPEND="
	dev-db/redis
"

BDEPEND="
	dev-vcs/git
	sys-apps/yarn
	net-libs/nodejs
"

PYTHON_COMPAT=( python3_9 )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 systemd

src_prepare() {
	eapply "${FILESDIR}/${PN}-server-path-notify.patch"

	default
}

src_configure() {
	(
		python -m venv --system-site-packages virtualenv
		distutils-r1_run_phase virtualenv/bin/python -m pip install --upgrade pip || die "Failed to install python packages"
		distutils-r1_run_phase virtualenv/bin/python -m pip install -r api/requirements.txt || die "Failed to install python packages"
	)

	pushd front || die
	tc-env_build yarn || die "Failed to install yarn packages"
	popd || die
}

src_compile() {
	pushd front || die
	tc-env_build yarn run build | tee /dev/stderr | (! grep -i 'ERROR in' ) || \
		die "Failed to build frontend"
	popd || die
}

src_install() {
	default

	local top="/srv/${PN}"
	diropts -o funkwhale -g funkwhale
	insopts -o funkwhale -g funkwhale
	insinto "${top}"/api/
	doins -r api/*

	insinto "${top}"/virtualenv/
	doins -r virtualenv/*

	local fn
	local venv="${top}/virtualenv"
	local py="${venv}/bin/python" 
	while read -r fn; do
		awk -v PY="$py" 'NR==1 { if (/^#!/) printf("#!%s\n", PY); else print } { print }' \
			< "$fn" > "${ED}/${venv}/bin/$(basename "${fn}")"
	done < <( find virtualenv/bin -maxdepth 1 -type f )

	insinto "${top}"/frontend/
	doins -r front/dist/*

	insinto "${top}"/config/
	doins "deploy/env.prod.sample"

	keepdir "${top}"/data/{media,static,music}

	insinto /usr/bin
	dobin "${FILESDIR}/funkwhale"

	systemd_dounit deploy/*.service deploy/*.target

}
