# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Install Update repos in transactional server
# Maintainer: qac team <qa-c@suse.de>

use base "consoletest";
use strict;
use warnings;
use testapi;
use qam;
use transactional;
use version_utils 'is_sle_micro';
use serial_terminal;

sub run {
    my ($self) = @_;

    select_serial_terminal;

    # Now we add the incident repositories and do a zypper patch
    add_test_repositories;
    record_info('Updates', script_output('zypper lu'));
    my $ret = trup_call('up', timeout => 300, proceed_on_failure => 1);
    process_reboot(trigger => 1);
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;
