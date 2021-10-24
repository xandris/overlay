# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="Account for media-sound/funkwhale"
ACCT_USER_ID=272
ACCT_USER_GROUPS=( funkwhale )

acct-user_add_deps
