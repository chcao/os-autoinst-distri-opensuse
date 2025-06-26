# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Modify the RAID disk by removing the the swap in md0 from
# the default proposal and create swap in md1.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base 'y2_module_consoletest';
use strict;
use warnings;
use testapi;
use utils;

sub run {
    select_console 'root-console';

    # Remove swap from md0
    assert_script_run 'swapoff /dev/md0 || true';
    assert_script_run 'sed -i "/\/dev\/md0/d" /etc/fstab';
    assert_script_run 'mdadm --zero-superblock /dev/md0 || true';
    assert_script_run 'mdadm --stop /dev/md0 || true';

    # Create swap on md1
    assert_script_run 'mkswap /dev/md1';
    assert_script_run 'echo "/dev/md1 swap swap defaults 0 0" >> /etc/fstab';
    assert_script_run 'swapon /dev/md1';
}

1;
