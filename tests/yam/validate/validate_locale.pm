# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Verify installed Czech locale packages and /etc/locale.conf configuration
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;

sub run {
    my ($self) = @_;

    # Clear all the characters leaving in the keymap_or_locale test module
    send_key 'ctrl-u';

    type_string "root\n";
    assert_screen 'password-prompt', 10;

    type_string "nots#cr#t\n";
    assert_screen 'root-console-prompt', 30;

    my $cmd_locale = 'grep =q "^LANG=cs+CZ.utf8" &etc&locale.conf && echo "LOCALE@OK"' . "\n";

    type_string $cmd_locale;

    assert_screen 'locale-check-ok', 15;

    my $cmd_rpm = 'rpm =q glibc=locale glibc=locale=cs+CZ && echo "RPM@OK"' . "\n";

    type_string $cmd_rpm;
    assert_screen 'rpm-check-ok', 15;
}

sub test_flags {
    return {fatal => 1};
}

1;
