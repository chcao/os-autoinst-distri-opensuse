# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Test podman login shell.
# - checks if podmansh runs and shell is indeed confined in the container
# - validates login through sudo, su, ssh and tty prompt
# Maintainer: QE-C team <qa-c@suse.de>

use strict;
use warnings;
use Mojo::Base 'containers::basetest';
use testapi;
use serial_terminal qw(select_serial_terminal select_user_serial_terminal);
use Utils::Systemd qw(systemctl);
use utils;
use containers::common;

my $src_image = "registry.opensuse.org/opensuse/tumbleweed";
my $quadlet_container = <<_EOF_;
[Unit]
Description=Podman shell container
After=local-fs.target

[Container]
Image=$src_image
ContainerName=podmansh
UserNS=keep-id
RunInit=yes
DropCapability=all
NoNewPrivileges=true

# change homedir to match user console serial terminal regexes
Environment=HOME=/home
WorkingDir=/home
Environment=SHELL=/bin/bash

# OpenQA serial terminal access
AddDevice=/dev/ttyS0

Exec=sleep infinity

[Quadlet]
# avoid infinite waiting for network by podman-user-wait-network-online.service
# https://github.com/systemd/systemd/issues/28762
DefaultDependencies=false

[Install]
RequiredBy=default.target
_EOF_

my $unit_name = 'podmansh.container';
my $quadlet_dir = '/etc/containers/systemd';
my $systemd_user_path;

my $initial_user_shell;

my $podman;

sub run {
    my ($self) = @_;
    select_serial_terminal;

    install_packages('podmansh policycoreutils-python-utils sudo');
    $podman = $self->containers_factory('podman');

    # make sure rootless user account exists
    ensure_user_account();

    # make sure rootless user is logged out
    ensure_user_serial_logged_out();
    select_serial_terminal;

    # terminate all (other) open rootless user sessions
    assert_script_run("loginctl terminate-user $username");
    script_retry("! loginctl list-users | grep $username", retry => 5, delay => 10, timeout => 10);

    # reset graphical user console after user termination
    console("user-console")->reset;

    # prepare normal user for testing
    prepare_user_account();

    # enable user linger - required for login using su or sudo
    # su/sudo does not create a systemd login session, which rootless podman depends on
    # https://github.com/containers/podman/issues/17202#issuecomment-1402604841
    assert_script_run("loginctl enable-linger $username");
    # wait for the user to start lingering
    script_retry("loginctl list-users | grep '$username.*lingering'", retry => 5, delay => 5, timeout => 10);

    # pre-pull the image
    script_retry("sudo -su $username sh -c 'cd; podman pull $src_image'", retry => 3, delay => 60, timeout => 180);

    # execute podman shell tests for multiple login methods
    record_info("Login by sudo");
    execute_tests("sudo -iu $username sh -c");
    record_info("Login by su");
    execute_tests("su --login $username -c");

    # disable linger and wait until user session is closed
    assert_script_run("loginctl disable-linger $username");
    script_retry("! loginctl list-users | grep $username", retry => 5, delay => 10, timeout => 10);

    record_info("Login by ssh");
    # execute podman shell tests through ssh
    execute_tests("ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q $username\@localhost");

    record_info("Login by console");
    # allow login podman from tty
    script_run('semanage boolean --modify --on local_login_containers');

    # Remove all previous commands generated by root. Some of these commands will be triggered
    # by the rootless user and will generate the same file /tmp/scriptX which will fail if it
    # already exists owned by root
    assert_script_run 'rm -rf /tmp/script*';
    ensure_serialdev_permissions;
    select_user_serial_terminal;

    # execute podman shell tests from tty with user login
    execute_tests("sh -c");
}

sub execute_tests {
    my $cmd = shift;

    # verifies if running in a podman container
    assert_script_run("$cmd 'test -e /run/.containerenv'");

    # verifies if running as expected user with expected groups
    validate_script_output("$cmd id", sub { /^uid=1000\(bernhard\) gid=1000\(bernhard\) groups=1000\(bernhard\)$/ });

    # verifies if correct image variant
    validate_script_output("$cmd 'cat /etc/os-release'", sub { /^ID=\"opensuse-tumbleweed\"$/m });
}

sub prepare_user_account {
    # create user container
    my $quadlet = '/usr/libexec/podman/quadlet';
    assert_script_run("mkdir -p $systemd_user_path");
    assert_script_run(qq(printf "$quadlet_container" >"$systemd_user_path/$unit_name"));
    record_info('Unit', script_output("sudo -su $username $quadlet -user -v -dryrun"));

    # change the default user shell to /usr/bin/podmansh
    $initial_user_shell = script_output("getent passwd $username | cut -d':' -f7");
    assert_script_run("usermod -s /usr/bin/podmansh $username");

    # prepare ssh key for passwordless login
    my $sshkeypath = "/root/.ssh/id_ed25519";
    if (script_run(qq(test -e "$sshkeypath.pub")) != 0) {
        assert_script_run(qq(ssh-keygen -t ed25519 -f "$sshkeypath" -q -N ""));
    }
    my $usersshpath = "/home/$username/.ssh";
    assert_script_run(qq(mkdir -p "$usersshpath" && chown "$username:$username" "$usersshpath"));
    assert_script_run(qq(tee -a "$usersshpath/authorized_keys" <"$sshkeypath.pub"));

    # change the dafault podmansh non-root shell to match user console serial terminal regexes
    # otherwise tty login fails
    my $containers_conf_d = "/home/$username/.config/containers/containers.conf.d";
    assert_script_run("mkdir -p $containers_conf_d");
    assert_script_run("printf '[podmansh]\\nshell = \"/bin/bash\"\\n' > $containers_conf_d/podmansh.conf");
    assert_script_run("chown -R $username:$username $containers_conf_d");
}

sub ensure_user_account {
    # Some products don't have bernhard pre-defined (e.g. SLE Micro)
    if (script_run("grep $username /etc/passwd") != 0) {
        assert_script_run "useradd -m $username";
        assert_script_run "echo '$username:$testapi::password' | chpasswd";
        # Make sure user has access to tty group
        my $serial_group = script_output "stat -c %G /dev/$testapi::serialdev";
        assert_script_run "grep '^${serial_group}:.*:${username}\$' /etc/group || (chown $username /dev/$testapi::serialdev && gpasswd -a $username $serial_group)";
    }
}

sub ensure_user_serial_logged_out {
    # select user serial (logs in if not already)
    select_user_serial_terminal;

    # exit the session
    enter_cmd("exit");

    # reset console
    console(current_console())->reset;
}

sub pre_run_hook {
    my $uid = script_output("id -u $username");
    $systemd_user_path = "$quadlet_dir/users/$uid";
}

sub cleanup {
    ensure_user_serial_logged_out();
    select_serial_terminal;

    # reset user shell
    script_run(qq(usermod -s "$initial_user_shell" "$username"));

    # cleanup podman
    $podman->cleanup_system_host();

    # disable linger and wait until user session is closed (if not already)
    script_run("loginctl disable-linger $username");
    script_retry("! loginctl list-users | grep $username", retry => 5, delay => 10, timeout => 10, die => 0);

    # remove leftover user configuration
    script_run(qq(rm -f "$systemd_user_path/$unit_name"));
    script_run(qq(rm -f "/home/$username/.config/containers/containers.conf.d/podmansh.conf"));
}

sub post_run_hook {
    cleanup();
}

sub post_fail_hook {
    cleanup();
}

1;
