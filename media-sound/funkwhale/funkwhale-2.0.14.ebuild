# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Federated audio server."
HOMEPAGE="https://funkwhale.audio/"
SRC_URI="https://dev.funkwhale.audio/${PN}/${PN}/-/archive/${PV/_rc/-rc}/${P}.tar.bz2"
RESTRICT="mirror"
PYTHON_COMPAT=( python3_{14,13} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=poetry-core

inherit distutils-r1 systemd multilib toolchain-funcs

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="ldap s3"

PATCHES=(
	"${FILESDIR}/${PN}-omit-config-package.patch"
	"${FILESDIR}/${PN}-server-path-notify.patch"
	"${FILESDIR}/${PN}-systemd-tweaks.patch"
	"${FILESDIR}/${PN}-1.3.0-subsonic-various-artists-hack.patch"
	"${FILESDIR}/${PN}-1.3.3-django-allauth-1.56.patch"
	"${FILESDIR}/${PN}-2.0.0-subsonic-errors.patch"
	"${FILESDIR}/${PN}-1.4.0-deprecations.patch"
)

# Need django-silk? optfeature?
DJANGO_RDEPEND='
	dev-python/dj-rest-auth[${PYTHON_USEDEP}]
	=dev-python/django-5*[${PYTHON_USEDEP}]
	>=dev-python/django-allauth-65.16[${PYTHON_USEDEP}]
	dev-python/django-cache-memoize[${PYTHON_USEDEP}]
	dev-python/django-cacheops[${PYTHON_USEDEP}]
	dev-python/django-cleanup[${PYTHON_USEDEP}]
	dev-python/django-cors-headers[${PYTHON_USEDEP}]
	dev-python/django-dynamic-preferences[${PYTHON_USEDEP}]
	dev-python/django-environ[${PYTHON_USEDEP}]
	dev-python/django-filter[${PYTHON_USEDEP}]
	>=dev-python/django-oauth-toolkit-3.1.0[${PYTHON_USEDEP}]
	dev-python/django-redis[${PYTHON_USEDEP}]
	dev-python/django-storages[${PYTHON_USEDEP}]
	dev-python/django-versatileimagefield[${PYTHON_USEDEP}]
	dev-python/djangorestframework[${PYTHON_USEDEP}]
	dev-python/drf-spectacular[${PYTHON_USEDEP}]
	dev-python/markdown[${PYTHON_USEDEP}]
	dev-python/persisting-theory[${PYTHON_USEDEP}]
	dev-python/psycopg:2[${PYTHON_USEDEP}]
	dev-python/redis[${PYTHON_USEDEP}]
'

LDAP_RDEPEND='
	dev-python/django-auth-ldap[${PYTHON_USEDEP}]
	dev-python/python-ldap[${PYTHON_USEDEP}]
	dev-libs/cyrus-sasl:2
	net-nds/openldap
'

CHANNELS_RDEPEND='
	dev-python/channels[${PYTHON_USEDEP}]
	dev-python/channels-redis[${PYTHON_USEDEP}]
'

CELERY_RDEPEND='
	dev-python/kombu[${PYTHON_USEDEP}]
	dev-python/celery[${PYTHON_USEDEP}]
'

# dev-python/websockets is because this ebuild uses uvicorn directly.
DEPLOYMENT_RDEPEND='
	www-servers/gunicorn[${PYTHON_USEDEP}]
	dev-python/uvicorn[${PYTHON_USEDEP}]

	dev-python/websockets[${PYTHON_USEDEP}]
'

LIBS_RDEPEND='
	dev-python/aiohttp[${PYTHON_USEDEP}]
	dev-python/arrow[${PYTHON_USEDEP}]
	dev-python/bleach[${PYTHON_USEDEP}]
	s3? (
		dev-python/boto3[${PYTHON_USEDEP}]
	)
	dev-python/click[${PYTHON_USEDEP}]
	dev-python/cryptography[${PYTHON_USEDEP}]
	dev-python/defusedxml[${PYTHON_USEDEP}]
	dev-python/feedparser[${PYTHON_USEDEP}]
	dev-python/python-ffmpeg[${PYTHON_USEDEP}]
	dev-python/liblistenbrainz[${PYTHON_USEDEP}]
	dev-python/musicbrainzngs[${PYTHON_USEDEP}]
	media-libs/mutagen[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pyld[${PYTHON_USEDEP}]
	dev-python/python-magic[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/requests-http-message-signatures[${PYTHON_USEDEP}]
	dev-python/watchdog[${PYTHON_USEDEP}]
	dev-python/troi[${PYTHON_USEDEP}]
	dev-python/lb-matching-tools[${PYTHON_USEDEP}]
	dev-python/unidecode[${PYTHON_USEDEP}]
	dev-python/pycountry[${PYTHON_USEDEP}]
'

DEPENDENCIES_PINNING_RDEPEND='
	dev-python/pluralizer[${PYTHON_USEDEP}]
	dev-python/service-identity[${PYTHON_USEDEP}]
	dev-python/unicode-slugify[${PYTHON_USEDEP}]
'

RDEPEND="$(python_gen_cond_dep "
	${DJANGO_RDEPEND}
	ldap? (
		${LDAP_RDEPEND}
	)
	${CHANNELS_RDEPEND}
	${CELERY_RDEPEND}
	${DEPLOYMENT_RDEPEND}
	${LIBS_RDEPEND}
	${DEPENDENCIES_PINNING_RDEPEND}

	acct-user/funkwhale
	acct-group/funkwhale
")"

BDEPEND="
	dev-vcs/git

	net-libs/nodejs

	dev-build/make

	dev-lang/rust
"

setup_npm() {
	export npm_config_prefix="${T}/npm_prefix"
	PATH="$npm_config_prefix/bin:${PATH}"
}

src_unpack() {
	default
}

src_prepare() {
	setup_npm || die
	npm i -g corepack || die

	printf '\ninstall:\n' >> Makefile # new Makefile in 1.4.0; lacks an 'install' target
	if ! use ldap; then
		eapply "${FILESDIR}/${PN}-1.3.1-disable-ldap.patch"
	fi

	if ! use s3; then
		eapply "${FILESDIR}/${PN}-2.0.0-disable-s3.patch"
	fi

	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m celery \\\\!" deploy/funkwhale-beat.service
	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m celery \\\\!" deploy/funkwhale-worker.service
	sed -Ei "/^ExecStart=/ s!=.*!="$PYTHON" -m gunicorn \\\\!" deploy/funkwhale-server.service

	distutils-r1_src_prepare
}

src_configure() {
	setup_npm || die
	pushd front || die
	tc-env_build yarn || die "Failed to install yarn packages"
	popd || die
}

src_compile() {
	setup_npm || die
	(cd api && distutils-r1_src_compile) || die
	local -x NODE_ENV=production
	local -x NODE_OPTIONS='--max-old-space-size=4096'
	local log="${T}/yarn-build-log.txt"
	pushd front || die
	tc-env_build yarn run build:deployment > "${log}" || die "Failed to build frontend"
	grep -q 'ERROR in' "${log}" && die "Failed to build frontend"
	popd || die
}

src_install() {
	default
	setup_npm || die
	distutils-r1_src_install

	local top="/srv/${PN}"
	local fn
	local header
	local dest
	local apifiles=()

	diropts -o funkwhale -g funkwhale
	insopts -o funkwhale -g funkwhale

	insinto "${top}"
	doins -r api/config

	insinto "${top}/frontend"
	doins -r front/dist/*

	newdoc "deploy/env.prod.sample" conf.d-funkwhale.sample

	newbin - funkwhale <<EOF
#!/usr/bin/env sh

systemd-run -qGPu funkwhale-cli \\
	-p EnvironmentFile=/etc/conf.d/funkwhale \\
	-p User=funkwhale \\
	-p Group=funkwhale \\
	--working-directory '${top}' \\
	"$PYTHON" -m funkwhale_api.main "\$@"
EOF

	systemd_dounit deploy/*.service deploy/*.target

	keepdir "${top}"/data/{media,static,music}
}
