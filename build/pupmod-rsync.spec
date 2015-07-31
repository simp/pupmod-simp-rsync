Summary: Rsync Puppet Module
Name: pupmod-rsync
Version: 4.2.0
Release: 2
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: hiera >= 1.2.1
Requires: pupmod-rsyslog >= 5.0.0
Requires: pupmod-stunnel >= 4.2.0-0
Requires: pupmod-concat >= 4.0.0-0
Requires: puppet >= 3.4.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-rsync-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure an rsync server.  The
intent is for this server to be run encrypted via a stunnel channel.

Client rsync rules have not been integrated into this module at this time.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/rsync

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/rsync
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/rsync

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/rsync

%files
%defattr(0640,root,puppet,0750)
%{prefix}/rsync

%post
#!/bin/sh

if [ -d %{prefix}/rsync/plugins ]; then
  /bin/mv %{prefix}/rsync/plugins %{prefix}/rsync/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Fri Jul 31 2015 Kendall Moore <kmoore@keywcorp.com> - 4.2.0.2
- Updated to use new rsyslog module.

* Wed May 06 2015 Chris Tessmer <chris.tessmer@onyxpoint.com> - 4.2.0-1
- Prevent file syncs during --noop runs.

* Thu Apr 02 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-0
- Made several changes, including one potentially breaking change, to make
  things consistent with modern types and providers.
  - Confine to Linux systems and systems with the command 'rsync'
  - Remove methods from the type and place them into the provider where
    possible.
  - Change 'do' to 'action' since 'do' is a reserved word in Ruby
  - Make 'password/pass' a provider for action on the system in the password
    files
  - No longer create custom resources in the type. This was causing issues with
    an invalid catalog when using PuppetDB
  - Pushed the management of /etc/rsync/secrets and /etc/rsync to server.pp
  - Moved server files to /etc/rsync/secrets and left client files in
    /etc/rsync so that we could properly use 'tidy'. This is currently noisy
    and we may need to pull in external Puppet patches to fix it.
  - Client-side passwords are no longer permanently housed on the system. If
    you need to troubleshoot the rsync connection, run Puppet in 'debug' mode
    and it will output the password in the log.

* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-6
- Migrated to the new 'simp' environment.

* Wed Oct 22 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-5
- Update to account for the stunnel module updates in 4.2.0-0

* Mon Jul 28 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Eliminated spurious 'to_a' call that may cause issues in Ruby 2

* Mon Jun 23 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Fixed SELinux check for when selinux_current_mode is not found.
- Fixed validation for $rsync::server::section::auth_user and
  $rsync::server::section::auth_pass.

* Sun Jun 22 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-3
- Removed MD5 file checksums for FIPS compliance.

* Tue Jun 03 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Added a boolean to turn off the useless rsyslog noise by default.

* Sat Apr 19 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Converted rsync::server::global to a class.

* Fri Apr 04 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-0
- Selinux booleans now set if mode != disabled

* Wed Mar 26 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Added native support for Stunnel
- Refactored the code to work well with Hiera
- Added spec tests

* Thu Jan 30 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-14
- Converted all string booleans to booleans.
- The rsync type required a call to 'to_a' on the existing tags to be
  able to update them within the type when using Puppet >= 3.4.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> - 4.0.0-13
- Updated all erb templates to properly scope variables.

* Wed Sep 25 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-12
- Modified the 'timeout' variable to connect to the 'contimeout' variable in
  rsync.
- Added an 'iotimeout' variable to set the 'timeout' variable in rsync.
- This is not intuitive but meets what most users expect the variables to
  actually do. This is noted in the documentation and will be fully modified
  during a later rewrite.

* Tue Sep 24 2013 Kendall Moore <kmoore@keywcorp.com> 4.0-12
- Require puppet 3.X and puppet-server 3.X because of an upgrade to use
  hiera instead of extdata.

* Tue Aug 06 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0-11
- No longer fail on SELinux specific errors. This handles the case
  where the Puppet server does not have any attributes in /srv/rsync
  but the clients are in Permissive or Enforcing mode.

* Thu Jun 27 2013 Kendall Moore <kmoore@keywcorp.com> - 4.0-10
- Set the rsync_export_all_ro boolean to true on both the server and client nodes
  to address an issue with backuppc initial setup on the backuppc server.

* Thu Jun 27 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0-10
- Set the rsync_client and rsync_export_all_ro booleans for rsync to function
  properly.
- Added an if block around the user password resource in the rsync type to
  avoid conflicts.
- Added a statement autorequiring the rsync_client selinux boolean to the rsync
  type prior to doing anything with rsync so that rsync can actually function
  properly.

* Mon Feb 25 2013 Maintenance
4.0-9
- The 'timeout' parameter is now a required value.
- Added extlookup('rsync_server',"$::rsync_server") as the default for the
  rsync_server variable so that it would work in a reasonable manner in most
  cases.
- Cleaned up some of the code in the rsync native type.

* Mon Jan 07 2013 Maintenance
4.0.0-8
- Created a Cucumber test to install and configure and rsync server and check to
  ensure the rsync service runs and its configuration file exists.

* Fri Aug 17 2012 Maintenance
4.0.0-7
- Moved all dynamic resource creation and checking to 'finish' instead of
  'initialize' in the custom type.

* Wed Jul 25 2012 Maintenance
4.0.0-6
- Updated the native type to create resources instead of munging files
  directly. This fixes repeated tidies that had been happening.

* Thu Jun 07 2012 Maintenance
4.0.0-5
- Ensure that Arrays in templates are flattened.
- Call facts as instance variables.
- Made compression, recusion, and hard link copying optional.
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
4.0.0-4
- Improved test stubs.

* Mon Dec 26 2011 Maintenance
4.0-3
- Updated the spec file to not require a separate file list.
- Scoped all of the top level variables.

* Mon Dec 05 2011 Maintenance
4.0-2
- Updated to not use 'size_only' by default since that loses one character
  changes in DNS, etc...

* Wed Nov 16 2011 Maintenance
4.0-1
- Updated the rsync type so that it gracefully handles the case where a
  password prompt is presented but no password has been provided.

* Tue Oct 25 2011 Maintenance
4.0-0
- Added a call to the tcpwrappers module with a default of ALL.
- Updated the rsync::server::section to add $client_nets to
  $hosts_allow

* Mon Oct 10 2011 Maintenance
2.0.0-3
- Updated to put quotes around everything that need it in a comparison
  statement so that puppet > 2.5 doesn't explode with an undef error.

* Fri Aug 12 2011 Maintenance
2.0.0-2
- Fixed a bug whereby the 'push' method passed through rsync::retrieve would
  not work.
- Added an rsync init script.
- Enhanced the custom type to ensure that all rsync items are called after the
  rsync and stunnel services if they exist.

* Tue Mar 29 2011 Maintenance - 2.0.0-1
- Rsync is now killed with a -9

* Thu Mar 24 2011 Maintenance - 1.0-6
- Several bugs were fixed in the rsync type that caused the type to fail when
  managing spaces with password protection.
- Removed the ability to set $pull in rsync::push
- Added rsync native type
- Fixed typos in rsync command and test command templates
- Updated to use concat_build and concat_fragment types

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Mon Jan 10 2011 Maintenance - 1-3
- Added the ability to push to the rsync server. Simply set $pull to 'false' on
  rsync::retrieve.

* Tue Oct 26 2010 Maintenance - 1-2
- Converting all spec files to check for directories prior to copy.

* Wed Jul 14 2010 Maintenance
1.0-0
- Update to support password protected rsync spaces.
  Passwords are auto-generated if required.

* Mon May 24 2010 Maintenance
1.0-0
- Doc update and code refactor.

* Thu May 13 2010 Maintenance
0.1-14
- Updated the 'exclude' param to match the man page. It works both with and
  without the '=' but not using '=' may be deprecated in the future.

* Wed Mar 17 2010 Maintenance
0.1-13
- Now supports --no-implied-dirs by default. This prevents errors when doing
  things like copying symlinks over directories, etc... It is a $no_implied_dirs
  variable and can be turned off by assigning it to 'false'.

* Mon Nov 02 2009 Maintenance
0.1-12
- Made this more flexible and hopefully faster by default.
- The define now supports the copy_links and size_only options.
