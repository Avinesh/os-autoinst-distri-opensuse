# Copyright 2023-2026 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Package: bpftrace
# Summary: Compile and attach eBPF probes with BCC tools
# Maintainer: kernel-qa@suse.de

use Mojo::Base 'opensusebasetest';
use testapi;
use package_utils 'install_package';
use version_utils qw(is_sle is_tumbleweed);
use serial_terminal 'select_serial_terminal';

sub run {
    select_serial_terminal;

    install_package('bcc-tools', trup_apply => 1);

    my $tools_dir = '/usr/share/bcc/tools';

    assert_script_run("$tools_dir/btrfsdist 5 2") unless is_tumbleweed;
    assert_script_run("$tools_dir/btrfsslower -d 10");
    assert_script_run("$tools_dir/filetop -a 5 10");
    assert_script_run("$tools_dir/runqlat 2 5");
}

sub test_flags {
    return {fatal => 0};
}

1;

=head1 Description

Smoke test for a small selection of BCC tools.
