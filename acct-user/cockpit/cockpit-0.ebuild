# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

KEYWORDS=~*
DESCRIPTION="Account for app-admin/cockpit"
ACCT_USER_ID=224
ACCT_USER_GROUPS=( cockpit )

acct-user_add_deps
