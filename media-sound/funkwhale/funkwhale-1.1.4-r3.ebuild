# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Federated audio server."
HOMEPAGE="https://funkwhale.audio/"
SRC_URI="https://dev.funkwhale.audio/${PN}/${PN}/-/archive/${PV}/${P}.tar.bz2"
RESTRICT="mirror"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	acct-user/funkwhale
	acct-group/funkwhale
	dev-db/postgresql
	sys-devel/make
	sys-libs/zlib
	virtual/jpeg

	>=dev-python/setuptools-49
	=dev-python/python-musicbrainzngs-0.7*
	=media-libs/mutagen-1.45*
	=dev-python/python-magic-0.4*
	=dev-python/click-7.1*
	=dev-python/feedparser-6.0*
	=dev-python/watchdog-1*
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

inherit python-single-r1 systemd

src_configure() {
	(
		python -m venv --system-site-packages virtualenv
		virtualenv/bin/python -m pip install --upgrade pip
		virtualenv/bin/python -m pip install -r api/requirements.txt
	)

	pushd front
	yarn
	popd
}

src_compile() {
	pushd front
	yarn run i18n-compile
	yarn run build | tee /dev/stderr | (! grep -i 'ERROR in' )
	popd
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
