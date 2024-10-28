# SUSE's openQA tests
#
# Copyright 2024 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Restore environmental variables which differ between the products involved in the upgrade.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;

sub run {
    # List the installed patterns and available patterns
    assert_script_run('zypper pt -i');
    assert_script_run('zypper pt -u');
}

1;
