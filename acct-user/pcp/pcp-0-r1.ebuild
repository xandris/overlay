# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="Account for app-admin/pcp"
ACCT_USER_ID=228
ACCT_USER_GROUPS=( pcp )

acct-user_add_deps
