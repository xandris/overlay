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
	eapply "${FILESDIR}/${PN}-server-path-notify.patch"
	eapply "${FILESDIR}/${PN}-nodejs-18.patch"
	eapply "${FILESDIR}/${PN}-python-3.11.patch"

	if ! use ldap; then
		eapply "${FILESDIR}/${PN}-disable-ldap.patch"
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
	einfo "EPYTHON: ${EPYTHON}"
	einfo "PYTHON: ${PYTHON}"

	if tc-is-cross-compiler; then
		einfo "Setting up cross virtualenv"
		"${EPYTHON}" -m venv build-venv || die "Failed to setup build-venv"

		einfo "Upgrading pip in virtualenv"
		build-venv/bin/python -m pip install -v --upgrade pip || die "Failed to upgrade pip"
		build-venv/bin/python -m pip install -v crossenv || die "Failed to install crossenv"
		build-venv/bin/python -m crossenv --sysroot "${ESYSROOT}" -vvv "${ESYSROOT}/${PYTHON}" cross-venv || "Failed to setup cross-virtualenv"

		cross-venv/bin/build-pip install "${pip_args[@]}" --upgrade pip || die "Failed to upgrade build pip"
		cross-venv/bin/cross-pip install "${pip_args[@]}" --upgrade pip || die "Failed to upgrade host pip"

		einfo "Installing cffi in virtualenv"
		cross-venv/bin/build-pip install "${pip_args[@]}" cffi || die "Failed to install build cffi"

		pip=cross-venv/bin/cross-pip

        # https://github.com/MagicStack/uvloop/pull/114
		local -x LIBUV_CONFIGURE_HOST="${CHOST}"

        # https://github.com/psycopg/psycopg2/issues/997
        local -x CFLAGS="${CFLAGS} -I${ESYSROOT}/usr/include"
        local -x LDFLAGS="${LDFLAGS} -L${ESYSROOT}/usr/$(get_abi_LIBDIR) -L${ESYSROOT}/$(get_abi_LIBDIR)"

		# lxml needs this
        local -x PKG_CONFIG='/usr/bin/cross-pkg-config'

		einfo "Installing 'wheel' into virtualenv"
		"$pip" install "${pip_args[@]}" wheel || die "Failed to install python package 'wheel'"

		case "${EPYTHON}" in
		pypy*)
		    # crossenv doesn't seem to get these into sysconfig
		    # distutils will look in the environment first, though.
			tc-export CC CXX AS LD RANLIB AR NM READELF STRIP OBJCOPY OBJDUMP
			
			local -x LDSHARED="${CC} -shared ${LDFLAGS}"

			# pypy doesn't seem to ship with this?

			# Variables for pyo3?
			local -x PYO3_CROSS=1
			local -x PYO3_CROSS_LIB_DIR
			PYO3_CROSS_LIB_DIR="$(get-pypy-libdir)" || die "Could not find pypy libdir"
			local -x PYO3_PYTHON="${ESYSROOT}/${PYTHON#/}"
			local -x PYO3_NO_PYTHON=1
			local -x PYO3_CONFIG_FILE="${HOME}/pyo3-config.txt"
			einfo "PYO3_CROSS=${PYO3_CROSS}"
			einfo "PYO3_CROSS_LIB_DIR=${PYO3_CROSS_LIB_DIR}"
			einfo "PYO3_PYTHON=${PYO3_PYTHON}"
			einfo "PYO3_CROSS_PYTHON_VERSION=3.9"
			einfo "PYO3_NO_PYTHON=${PYO3_NO_PYTHON}"
			einfo "PYO3_CONFIG_FILE=${PYO3_CONFIG_FILE}"

			# Cargo can't tell the target arch
			mkdir -p "${HOME}/.cargo" || die "Could not create cargo config dir"
			cat >>"${HOME}/.cargo/config.toml" <<-EOF
			[build]
			jobs = $(makeopts_jobs)
			target = "${CHOST}"
			EOF

			cat >>"${HOME}/pyo3-config.txt" <<-EOF
			implementation=PyPy
			version=3.9
			shared=true
			abi3=true
			EOF
			;;
		esac
	else
		einfo "Setting up virtualenv"
		"${EPYTHON}" -m venv virtualenv

		pip=virtualenv/bin/pip

		einfo "Upgrading pip in virtualenv"
		"$pip" install "${pip_args[@]}" --upgrade pip || die "Failed to upgrade pip"

		einfo "Installing 'wheel' into virtualenv"
		"$pip" install "${pip_args[@]}" wheel || die "Failed to install python package 'wheel'"
	fi

	einfo "Installing Pillow in virtualenv"
	"$pip" install "${pip_args[@]}" $(grep '^Pillow' api/requirements/base.txt) \
		--global-option=build_ext \
		--global-option=--disable-{tiff,freetype,raqm,lcms,webp{,mux},jpeg2000,imagequant,xcb} \
		--global-option=-j$(makeopts_jobs) \
		|| die "Failed to install Pillow"

	einfo "Installing ${PN} API requirements in virtualenv"
	"$pip" install "${pip_args[@]}" -r api/requirements.txt \
		|| die "Failed to install python packages"

	local uninst=( )

	case "${PYTHON}" in
	pypy*)
		uninst+=( wheel )
		;;
	esac

	uninst+=( pip )

	"$pip" uninstall -y "${uninst[@]}"

	pushd front || die
	tc-env_build yarn || die "Failed to install yarn packages"
	find node_modules/fomantic-ui-css -name '*.css' -print0 | xargs -0 sed -i 's/;;/;/g'
	popd || die
}

src_compile() {
	local -x NODE_ENV=production
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
