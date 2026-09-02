# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Verify the system is booted with systemd-boot
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use Mojo::Base 'consoletest';
use testapi;
use utils;

sub run {
    select_console 'root-console';

    my $output = script_output('SYSTEMD_COLORS=0 bootctl status', proceed_on_failure => 1);

    record_info('bootctl status', $output);

    unless ($output =~ /Product:\s+systemd-boot/i) {
        die "Validation failed: Current Boot Loader Product is not 'systemd-boot'!\nOutput:\n$output";
    }
}

sub post_fail_hook {
    my ($self) = @_;

    script_run('efibootmgr -v > /tmp/efibootmgr.log');
    script_run('bootctl status > /tmp/bootctl_status.log');
    upload_logs('/tmp/efibootmgr.log');
    upload_logs('/tmp/bootctl_status.log');

    $self->SUPER::post_fail_hook();
}

sub test_flags {
    return {fatal => 1};
}

1;
