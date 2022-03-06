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
		=dev-python/pyopenssl-20.0*
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

PYTHON_COMPAT=( python3_9 )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 systemd multiprocessing

src_prepare() {
	eapply "${FILESDIR}/${PN}-server-path-notify.patch"

	if ! use ldap; then
		eapply "${FILESDIR}/${PN}-disable-ldap.patch"
	fi

	default
}


src_configure() {
	local pip

	if tc-is-cross-compiler; then
		"${EPYTHON}" -m venv build-venv || die "Failed to setup build-venv"
		build-venv/bin/python -m pip install -v --upgrade pip || die "Failed to upgrade pip"
		build-venv/bin/python -m pip install -v crossenv || die "Failed to install crossenv"
		build-venv/bin/python -m crossenv --sysroot "${ESYSROOT}" -vvv "${ESYSROOT}/${PYTHON}" cross-venv || "Failed to setup cross-virtualenv"

		cross-venv/bin/build-pip install -v --upgrade pip || die "Failed to upgrade build pip"
		cross-venv/bin/cross-pip install -v --upgrade pip || die "Failed to upgrade host pip"
		cross-venv/bin/build-pip install -v cffi || die "Failed to install build cffi"

		pip=cross-venv/bin/cross-pip

        # https://github.com/MagicStack/uvloop/pull/114
		local -x LIBUV_CONFIGURE_HOST="${CHOST}"

        # https://github.com/psycopg/psycopg2/issues/997
        local -x CFLAGS="-I${ESYSROOT}/usr/include"
        local -x LDFLAGS="-L${ESYSROOT}/usr/$(get_abi_LIBDIR) -L${ESYSROOT}/$(get_abi_LIBDIR)"

		# lxml needs this
        local -x PKG_CONFIG='/usr/bin/cross-pkg-config'

		"$pip" install -v $(grep '^Pillow' api/requirements/base.txt) \
			--global-option=build_ext \
			--global-option=--disable-{platform-guessing,tiff,freetype,raqm,lcms,webp{,mux},jpeg2000,imagequant,xcb} \
			--global-option=-j$(makeopts_jobs) \
			--install-option=--no-compile \
			|| die "Failed to install Pillow"

		"$pip" install -v --install-option=--no-compile -r api/requirements.txt \
			|| die "Failed to install python packages"
	else
		"${EPYTHON}" -m venv virtualenv

		pip=cross-venv/bin/cross-pip

		"$pip" install -v --upgrade pip || die "Failed to install python packages"

		"$pip" install -v $(grep '^Pillow' api/requirements/base.txt) \
			--global-option=build_ext \
			--global-option=--disable-{platform-guessing,tiff,freetype,raqm,lcms,webp{,mux},jpeg2000,imagequant,xcb} \
			--global-option=-j$(makeopts_jobs) \
			--install-option=--no-compile \
			|| die "Failed to install Pillow"

		"$pip" install -v -r api/requirements.txt || die "Failed to install python packages"
	fi

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
	local venv="${top}/virtualenv"
	local py="${venv}/bin/python" 
	local srcvenv=virtualenv
	local hostpython="${PYTHON}"

	if tc-is-cross-compiler; then
		srcvenv=cross-venv/cross
		local -x PYTHON="cross-venv/bin/cross-python"
	fi

	diropts -o funkwhale -g funkwhale
	insopts -o funkwhale -g funkwhale

	insinto "${top}"/virtualenv/
	doins -r "${srcvenv}"/*

	insinto "${top}"/api/
	doins -r api/*

	#find "${ED}/${top#/}/api" "${ED}/${venv#/}" -depth -type d \
		#\( -name '*.dist-info' -o -name '*.egg-info' \) -exec rm -r {} + || die "Failed to remove extraneous files"

	python_optimize "${ED}/${venv#/}/lib" "${ED}/${top#/}/api" || die "Failed to optimize Python packages"

	local fn
	local header
	local dest

	while read -r fn; do
		dest="${ED}/${venv#/}/bin/${fn##*/}"

		if [[ ${fn##*/} == python ]]; then
			ln -sf "${hostpython}" "${dest}" || die "Failed to symlink host's python to ${dest#${ED}}"
			continue
		fi

		read -rN 2 header < "${fn}"
		if [[ ${header} == '#!' ]]; then
			rm "$dest"
			awk -v PY="${py}" 'NR==1 { if (/^#!/) printf("#!%s\n", PY); else print } NR>1 { print }' \
				< "${fn}" > "${dest}" || die "Failed to tweak shebang for ${dest#${ED}}"
			chown funkwhale:funkwhale "${dest}"
			chmod 755 "${dest}"
		fi
	done < <( find "${srcvenv}"/bin -maxdepth 1 -type f ) || die "Failed to tweak shebangs"

	insinto "${top}"/frontend/
	doins -r front/dist/*

	insinto "${top}"/config/
	doins "deploy/env.prod.sample"

	keepdir "${top}"/data/{media,static,music}

	insinto /usr/bin
	dobin "${FILESDIR}/funkwhale"

	systemd_dounit deploy/*.service deploy/*.target
}
