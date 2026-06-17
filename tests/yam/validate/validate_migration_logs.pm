# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Validate logs after migration to sle 16.
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use Mojo::Base 'consoletest';
use testapi;
use utils 'upload_folders';

sub run {
    select_console 'root-console';

    upload_logs("/var/log/distro_migration.log", failok => 1);
    script_run 'tar zcvf /tmp/cache_wicked_config.tar.gz /var/cache/wicked_config/*';
    upload_logs("/tmp/cache_wicked_config.tar.gz", failok => 1);
    script_run 'tar zcvf /tmp/cache_udev_rules.tar.gz /var/cache/udev_rules/*';
    upload_logs("/tmp/cache_udev_rules.tar.gz", failok => 1);
    script_run("tar czvf /tmp/udev_rules.tar.gz /etc/udev/rules.d/*", {timeout => 60});
    upload_logs("/tmp/udev_rules.tar.gz", failok => 1);

    ## provide zypp log for developer
    assert_script_run('tar -czvf /tmp/migration_debug_logs.tar.gz ' .
                      '-C /var/log/ ' .
                      '--ignore-failed-read ' .
                      'YaST2 zypper.log pk_backend_zypp updateTestcase-*');

    # Upload the tarball if it exists, otherwise dump /var/log contents
    if (script_run('test -f /tmp/migration_debug_logs.tar.gz') == 0) {
        upload_logs('/tmp/migration_debug_logs.tar.gz');
    } else {
        # If the tarball wasn't created, change directory to /var/log and grab the full list
        my $log_list = script_output('cd /var/log && ls -la');

        # Display the full directory listing directly inside the openQA Web UI
        record_info('Missing Tarball', "The archive could not be found.\n\nHere is the listing of /var/log:\n\n$log_list", result => 'fail');
    }

    my $fatal_errors = script_output("cat /var/log/distro_migration.log | grep -i -E \"migration failed|aborting migration\" -B50", proceed_on_failure => 1);
    if ($fatal_errors) {
        record_info("Migration failed", $fatal_errors, result => 'fail');
        die("Migration failed");
    }

    my $minor_errors = script_output("cat /var/log/distro_migration.log | grep -ivE \"\\-errors?|errors?\\-|error=''\" | grep -iE \"failed|failure|error\" -B50", proceed_on_failure => 1);
    record_info("Minor errors", $minor_errors, result => 'fail') if ($minor_errors);
}

sub test_flags {
    return {fatal => 0};
}

sub post_fail_hook {
    upload_logs("/boot/grub2/grub.cfg", failok => 1);
    upload_folders(folders => '/etc/zypp/repos.d/');
}

1;
