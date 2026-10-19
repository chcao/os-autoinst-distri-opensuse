# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# Summary: Verify system information commands (os-release, zypper lr, SUSEConnect)
# Maintainer: QA Team <qa@suse.de>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;

sub run {

    # Ensure root console is active
    select_console('root-console');

    # 1. Check /etc/os-release
    assert_script_run('cat /etc/os-release');

    # 2. Check enabled package repositories and URLs
    assert_script_run('zypper lr -u');

    # 3. Check registration status
    assert_script_run('SUSEConnect --status-text');
}

sub test_flags {
    return { fatal => 1 };
}

1;
