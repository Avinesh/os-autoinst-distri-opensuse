# SUSE's openQA tests
#
# Copyright 2017-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Package: autoconf automake gcc git-core make
# Summary: Tests for kernel live patching infrastructure
# Maintainer: Ondřej Súkup <osukup@suse.cz>

use File::Basename 'basename';

use Mojo::Base 'opensusebasetest';
use testapi;
use serial_terminal 'select_serial_terminal';
use utils;
use registration;
use version_utils 'is_sle';
use transactional;
use package_utils;
use kernel;
use Kernel::utils qw(is_debugfs_mounted enable_debugfs);

sub run {
    if (get_var('AZURE')) {
        record_info("Azure don't have kGraft/LP infrastructure");
        return;
    }

    my $git_repo = get_required_var('QA_TEST_KLP_REPO');
    my $dir = basename($git_repo);
    $dir =~ s/\.git$//;

    (is_sle(">12-sp1") || !is_sle) ? select_serial_terminal() : select_console('root-console');

    add_suseconnect_product("sle-sdk") if (is_sle('<12-SP5'));
    install_package('autoconf automake gcc git make');

    enable_debugfs() unless is_debugfs_mounted();

    if (script_run('[ -d /lib/modules/$(uname -r)/build ]') != 0) {
        # The "build" symlink comes from kernel-<flavor>-devel.
        # Install it explicitly and pin it to the installed kernel.
        my $devel_libs = get_kernel_devel_libs;
        (my $kernel_pack = $devel_libs) =~ s/-devel$//;
        my $kver = script_output("rpm -q --qf '%{VERSION}-%{RELEASE}' $kernel_pack");

        install_package(join(' ', get_kernel_devel_flavor, "$devel_libs=$kver"), trup_continue => 1);
    }

    reboot_on_changes;

    assert_script_run('[ -d /lib/modules/$(uname -r)/build ]', fail_message => 'Kernel build directory is missing after installing the devel package');

    assert_script_run('git config --global http.sslVerify false');
    assert_script_run('git clone ' . $git_repo);
    assert_script_run("cd $dir");
    record_info('qa_test_klp', script_output("git show | tee"));
    record_info('bats', script_output("which bats 2>&1", proceed_on_failure => 1));
    assert_script_run("./run.sh", timeout => 300);
}

1;

=head1 Example configuration

=head2 QA_TEST_KLP_REPO

Git repository for kernel live patching infrastructure tests.
QA_TEST_KLP_REPO=https://github.com/SUSE/qa_test_klp.git

=cut
