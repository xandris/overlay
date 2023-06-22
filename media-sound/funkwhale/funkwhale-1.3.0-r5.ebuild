# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Federated audio server."
HOMEPAGE="https://funkwhale.audio/"
SRC_URI="https://dev.funkwhale.audio/${PN}/${PN}/-/archive/${PV}/${P}.tar.bz2"
RESTRICT="mirror network-sandbox"
PYTHON_COMPAT=( python3_{11,10,9} pypy3 )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_SETUPTOOLS=no

inherit distutils-r1 systemd multiprocessing

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~arm64"
IUSE="ldap s3"


PATCHES=(
	"${FILESDIR}/${PN}-server-path-notify.patch"
	"${FILESDIR}/${PN}-systemd-tweaks.patch"
	"${FILESDIR}/${P}-subsonic-various-artists-hack.patch"
)

# Compile-time only dependencies
# Including libraries needed to 'pip install' but optional at runtime.
RDEPEND="
	$(python_gen_cond_dep '
		dev-python/aiohttp[${PYTHON_USEDEP}]
		dev-python/arrow[${PYTHON_USEDEP}]
		dev-python/bleach[${PYTHON_USEDEP}]
		dev-python/celery[${PYTHON_USEDEP}]
		dev-python/click[${PYTHON_USEDEP}]
		dev-python/cryptography[${PYTHON_USEDEP}]
		dev-python/channels[${PYTHON_USEDEP}]
		dev-python/channels-redis[${PYTHON_USEDEP}]
		dev-python/daphne[${PYTHON_USEDEP}]
		dev-python/dj-rest-auth[${PYTHON_USEDEP}]
		=dev-python/django-3*[${PYTHON_USEDEP}]
		dev-python/django-allauth[${PYTHON_USEDEP}]
		dev-python/django-cache-memoize[${PYTHON_USEDEP}]
		dev-python/django-cacheops[${PYTHON_USEDEP}]
		dev-python/django-cleanup[${PYTHON_USEDEP}]
		dev-python/django-cors-headers[${PYTHON_USEDEP}]
		dev-python/django-dynamic-preferences[${PYTHON_USEDEP}]
		dev-python/django-environ[${PYTHON_USEDEP}]
		dev-python/django-filter[${PYTHON_USEDEP}]
		<dev-python/django-oauth-toolkit-2.3.0[${PYTHON_USEDEP}]
		dev-python/django-redis[${PYTHON_USEDEP}]
		dev-python/django-versatileimagefield[${PYTHON_USEDEP}]
		dev-python/drf-spectacular[${PYTHON_USEDEP}]
		dev-python/feedparser[${PYTHON_USEDEP}]
		dev-python/kombu[${PYTHON_USEDEP}]
		dev-python/markdown[${PYTHON_USEDEP}]
		dev-python/msgpack[${PYTHON_USEDEP}]
		dev-python/persisting-theory[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/pluralizer[${PYTHON_USEDEP}]
		dev-python/psycopg:2[${PYTHON_USEDEP}]
		dev-python/pydub[${PYTHON_USEDEP}]
		dev-python/pyld[${PYTHON_USEDEP}]
		dev-python/python-magic[${PYTHON_USEDEP}]
		dev-python/python-musicbrainzngs[${PYTHON_USEDEP}]
		dev-python/pytz[${PYTHON_USEDEP}]
		dev-python/redis[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/requests-http-message-signatures[${PYTHON_USEDEP}]
		dev-python/sentry-sdk[${PYTHON_USEDEP}]
		dev-python/service-identity[${PYTHON_USEDEP}]
		dev-python/unicode-slugify[${PYTHON_USEDEP}]
		dev-python/uvicorn[${PYTHON_USEDEP}]
		dev-python/watchdog[${PYTHON_USEDEP}]
		dev-python/websockets[${PYTHON_USEDEP}]
		media-libs/mutagen[${PYTHON_USEDEP}]
		www-servers/gunicorn[${PYTHON_USEDEP}]

		ldap? (
			dev-python/django-auth-ldap[${PYTHON_USEDEP}]
			dev-python/python-ldap[${PYTHON_USEDEP}]
		)

		s3? (
			dev-python/boto3[${PYTHON_USEDEP}]
		)
	')

	ldap? (
		dev-libs/cyrus-sasl:2
		net-nds/openldap
	)

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

src_prepare() {
	if ! use ldap; then
		eapply "${FILESDIR}/${P}-disable-ldap.patch"
	fi

	if ! use s3; then
		eapply "${FILESDIR}/${P}-disable-s3.patch"
	fi

	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m celery \\\\!" deploy/funkwhale-beat.service
	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m celery \\\\!" deploy/funkwhale-worker.service
	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m gunicorn \\\\!" deploy/funkwhale-server.service

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
	local fn
	local header
	local dest
	local apifiles=()

	diropts -o funkwhale -g funkwhale
	insopts -o funkwhale -g funkwhale

	insinto "${top}/frontend"
	doins -r front/dist/*

	insinto "${top}/api"
	doins -r api/*

	newdoc "deploy/env.prod.sample" conf.d-funkwhale.sample

	newbin - funkwhale <<EOF
#!/usr/bin/env sh

systemd-run -qGPu funkwhale-cli \\
	-p EnvironmentFile=/etc/conf.d/funkwhale \\
	-p User=funkwhale \\
	-p Group=funkwhale \\
	--working-directory /srv/funkwhale/api \\
	"$PYTHON" -m funkwhale_api.main "\$@"
EOF

	systemd_dounit deploy/*.service deploy/*.target

	keepdir "${top}"/data/{media,static,music}

	python_optimize "${ED}/${top#/}/api" || die "Failed to optimize Python packages"
}
