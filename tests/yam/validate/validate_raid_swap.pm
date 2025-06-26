# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Validate the /etc/fstab doesn't have md0 as swap but has md1 instead.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base 'y2_module_consoletest';
use strict;
use warnings;
use testapi;

sub run {
    select_console 'root-console';

    # Validate /etc/fstab doesn't have md0 as swap
    assert_script_run '! grep -q "/dev/md0.*swap" /etc/fstab';

    # Validate /etc/fstab has md1 as swap
    assert_script_run 'grep -q "/dev/md1.*swap" /etc/fstab';

    # Validate only md1 is active as swap
    assert_script_run 'swapon --summary | grep -q "^/dev/md1"';
    assert_script_run '! swapon --summary | grep -q "^/dev/md0"';

    # Optionally: validate RAID status
    assert_script_run 'cat /proc/mdstat';
}

1;
