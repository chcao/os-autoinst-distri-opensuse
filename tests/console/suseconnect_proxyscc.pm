# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Check registration status and reregister system via proxySCC.
#
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>
use base "consoletest";
use strict;
use warnings;
use testapi;
use serial_terminal 'select_serial_terminal';
use registration;
use utils 'zypper_call';
use version_utils 'is_sle';

sub run {
    my $u = get_var("SCC_URL");
    my $reg_code = get_required_var("SCC_REGCODE");
    my $arch = get_required_var("ARCH");

    select_console 'root-console';;

    # Check the registration status
    assert_script_run "SUSEConnect -s | grep 'Not Registered'";
    assert_script_run "SUSEConnect --status-text";

    # To register the system against proxySCC, set the proxySCC url to /etc/SUSEConnect
    enter_cmd "echo 'url: $u' > /etc/SUSEConnect";
    assert_script_run "SUSEConnect -r $reg_code", 180;
    assert_script_run "SUSEConnect --status-text| grep -v 'Not Registered'";
    zypper_call 'ref';
    assert_script_run "SUSEConnect --list-extensions";

    assert_script_run "SUSEConnect --status";
    assert_script_run "SUSEConnect -d || SUSEConnect --cleanup";
    assert_script_run "SUSEConnect --status-text";

}

sub test_flags {
    return {always_rollback => 1};
}

1;
