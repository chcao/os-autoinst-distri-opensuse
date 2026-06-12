# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Check the pattern list
#
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use Mojo::Base 'consoletest';
use testapi;
use utils;
use registration;

sub run {
    select_console 'root-console';
    
    # Check the default installation patterns
    record_info("list all patterns", script_output("zypper -n search -t pattern"));
    record_info("list installed patterns", script_output("zypper -n search -i -t pattern"));

    if (get_var("REGISTER_PHUB")) {
        add_suseconnect_product(get_addon_fullname('phub'));
	record_info("list all patterns with phub", script_output("zypper -n search -t pattern"));
        record_info("list installed patterns", script_output("zypper -n search -i -t pattern"));
    }
}

1;
