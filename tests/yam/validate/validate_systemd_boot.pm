# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Verify the system is booted with systemd-boot
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use base 'consoletest';
use strict;
use warnings;
use testapi;

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    my $output = script_output('bootctl status');

    unless ($output =~ /Current Boot Loader:.*Product:\s+systemd-boot/s) {
        die "Validation failed: System was not booted with systemd-boot!\nOutput:\n$output";
    }

    validate_script_output 'bootctl status', sub { /Current Boot Loader:.*systemd-boot/s };

    record_info('Validation Passed', 'Successfully booted with systemd-boot');
}

sub post_fail_hook {
    my $self = shift;
    script_run('efibootmgr -v > /tmp/efibootmgr.log');
    upload_logs('/tmp/efibootmgr.log');
    $self->SUPER::post_fail_hook();
}

1;
