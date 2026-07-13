# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-rsync` is a SIMP Puppet module that manages both sides of rsync: an
**rsync server** (an `rsyncd` daemon whose `/etc/rsyncd.conf` is assembled from
`concat` fragments, normally fronted by **stunnel** for encryption) and an
**rsync client** (a custom `rsync` resource type plus the `rsync::retrieve` /
`rsync::push` defines that drive file transfers). The base `rsync` class
(`manifests/init.pp`) installs the `rsync` package, creates the purged
`/etc/rsync` directory, and toggles the relevant SELinux booleans.

The client side exists because Puppet's native fileserving type is limited; the
custom `rsync` type (`lib/puppet/type/rsync.rb`) and provider
(`lib/puppet/provider/rsync/rsync.rb`) shell out to the `rsync` binary and treat
"needs a transfer" as the resource's out-of-sync condition
(`lib/puppet/provider/rsync/rsync.rb`).

### Business logic

Public API: the base class `rsync`, the class `rsync::server`, the define
`rsync::server::section`, and the client defines `rsync::retrieve` and
`rsync::push`. `rsync::selinux` and `rsync::server::global` are internal
(only `rsync::server::global` actually calls `assert_private()`). There is also
one custom resource type, `rsync`, shipped in `lib/`.

- **`rsync` (`manifests/init.pp`)** — Public base class. Parameters
  (`init.pp`): six `Boolean` SELinux-boolean toggles
  (`$sebool_anon_write` default `false`, `$sebool_client` default `true`,
  `$sebool_export_all_ro` default `true`, `$sebool_full_access` default `false`,
  `$sebool_use_nfs`/`$sebool_use_cifs` default `false` — the last two are
  documented as El6-only and slated for removal), and `$package_ensure`
  (`String`) from the `simp_options::package_ensure` seam (`init.pp`). Body:
  `simplib::assert_metadata($module_name)` (`init.pp`), `package { 'rsync' }`
  (`init.pp`), `file { '/etc/rsync' }` as a **purged** `0640` directory
  (`init.pp`), and — only when SELinux is enabled (not `disabled`) —
  `include 'rsync::selinux'` (`init.pp`).
- **`rsync::selinux` (`manifests/selinux.pp`)** — Internal class (**not**
  `assert_private()`'d, but only reached via `include` from `init.pp`). Maps
  four `$rsync::sebool_*` booleans to `on`/`off` and sets the `selboolean`
  resources `rsync_client`, `rsync_export_all_ro`, `rsync_anon_write`,
  `rsync_full_access` (`selinux.pp`). Note: `$sebool_use_nfs` /
  `$sebool_use_cifs` are declared on the base class but **not** consumed here.
- **`rsync::server` (`manifests/server.pp`)** — Public class. Parameters
  (`server.pp`): `$stunnel` (`Boolean`, from `simp_options::stunnel`,
  default `true`), `$stunnel_port` (`Simplib::Port`, `8730`), `$listen_address`
  (`Simplib::IP`, `0.0.0.0`), `$drop_rsyslog_noise` (`Boolean`, `true`),
  `$firewall` (from `simp_options::firewall`, default `false`), `$trusted_nets`
  (from `simp_options::trusted_nets`, default `['127.0.0.1']`), `$package_ensure`
  (from `simp_options::package_ensure`, default `'installed'`), and `$package`
  (`String`, **no default** — supplied from module data). Body: `include
  '::rsync'` and `include '::rsync::server::global'` (`server.pp`);
  `ensure_resource('package', $package, ...)` rather than a plain `package`
  resource because on some OSes the client package already ships the daemon
  files (`server.pp`); an stunnel-vs-firewall branch (`server.pp`) —
  with stunnel it declares `stunnel::connection { 'rsync_server' }` and
  subscribes the service to `Service['stunnel']`, otherwise (if `$firewall`) it
  opens the port via `iptables::listen::tcp_stateful`; the `concat`
  `/etc/rsyncd.conf` at `0400` (`server.pp`); a systemd-vs-SysV
  `service { 'rsyncd' }` branch keyed on `'systemd' in $facts['init_systems']`
  (`server.pp`, the SysV branch drops the `files/rsync.init` script); and,
  when `$drop_rsyslog_noise`, `include '::rsyslog'` plus two `rsyslog::rule::drop`
  rules that discard rsyncd chatter and localhost noise (`server.pp`).
- **`rsync::server::global` (`manifests/server/global.pp`)** — **Private**
  (`assert_private()` at `global.pp`). Builds the global section of
  `/etc/rsyncd.conf`. Parameters include `$port` (`Simplib::Port`, `873`),
  `$address` (`Simplib::IP`, `127.0.0.1` — the stunnel back end), `$trusted_nets`
  and `$tcpwrappers` (from the `simp_options` seam). `include '::rsync::server'`
  (`global.pp`); optional `tcpwrappers::allow` (`global.pp`); on SELinux
  systems a `vox_selinux::port` labelling the port `rsync_port_t`
  (`global.pp`); and `concat::fragment { 'rsync_global' }` at order 5 from
  `templates/rsyncd.conf.global.erb` (`global.pp`).
- **`rsync::server::section` (`manifests/server/section.pp`)** — Public
  define. Emits one rsyncd share (module) into `/etc/rsyncd.conf` as
  `concat::fragment` at order 10 (`section.pp`), and when `$auth_users`
  or `$user_pass` is set, writes `/etc/rsync/${name}.rsyncd.secrets` at `0600`
  with `show_diff => false` (`section.pp`). `$path` is required; many
  rsyncd knobs are exposed (`read_only` default `true`, `use_chroot` default
  `false`, `hosts_allow` from `simp_options::trusted_nets`, `hosts_deny` default
  `'*'`, etc.).
- **`rsync::retrieve` (`manifests/retrieve.pp`)** — Public define; the
  real client entry point. Declares one `rsync { $name }` custom-type resource
  (`retrieve.pp`) and `include '::rsync'` (`retrieve.pp`). Password
  handling (`retrieve.pp`): if `$pass` is given it is used verbatim;
  else if `$user` is given the password is looked up via
  `simplib::passgen($user)`; else `undef`. `$pull` (default `true`) selects the
  `pull`/`push` action (`retrieve.pp`). `$rsync_server` defaults to
  `simplib::lookup('simp_options::rsync::server')` **with no default_value**
  (`retrieve.pp`).
- **`rsync::push` (`manifests/push.pp`)** — Public define. A thin wrapper:
  it simply declares `rsync::retrieve { "push_${name}" }` with `pull => false`
  (`push.pp`). Present "for clarity" per its own docstring
  (`push.pp`).
- **`rsync` custom type** (`lib/puppet/type/rsync.rb`) — Runs an `rsync` command;
  most parameters map directly to rsync(1) flags. It defines many **aliased**
  parameter pairs (`source`/`source_path`, `target`/`target_path`,
  `server`/`rsync_server`, `protocol`/`proto`, `timeout`/`rsync_timeout`/
  `contimeout`, `password`/`pass`) and its `validate` block rejects specifying
  both members of a pair (`type/rsync.rb`). The `action` property accepts
  `push`/`pull` (default `pull`) and its `insync?` delegates to the provider's heavyweight
  `action_insync?`, which actually performs the transfer
  (`type/rsync.rb`, `provider/rsync/rsync.rb`).

### Gotchas / non-obvious details

- **`rsync::retrieve`'s `$rsync_server` lookup has NO default.** `retrieve.pp`
  calls `simplib::lookup('simp_options::rsync::server')` without a
  `default_value`, so if the parameter is not passed and the key is not in
  Hiera, catalog compilation **fails** for that resource. This is unlike every
  other `simplib::lookup` in the module, which supply explicit defaults.
- **`rsync::bwlimit` is a module-local lookup, not a `simp_options` key.**
  `retrieve.pp` resolves `simplib::lookup('rsync::bwlimit', { 'default_value'
  => undef })` — it is a plain module parameter lookup, not part of the shared
  `simp_options::*` namespace.
- **The daemon package comes from module data, not a fixed name.**
  `rsync::server` has `$package` with no default (`server.pp`); it is set to
  `rsync-daemon` in `data/common.yaml` and overridden to `rsync` for Amazon 2
  (`data/os/Amazon-2.yaml`). `ensure_resource` (not `package`) is used because on
  some OSes the client `rsync` package already contains the daemon files
  (`server.pp`), so both the base class and the server may reference the
  same package name.
- **The server defaults to encrypted (stunnel).** `$stunnel` defaults to `true`
  (`server.pp`); `rsync::server::global` binds the daemon to `127.0.0.1`
  (`global.pp`) and stunnel accepts on `$listen_address:8730` and forwards
  to it (`server.pp`). Turning stunnel off exposes the daemon directly and
  switches security over to the `$firewall` / tcpwrappers paths.
- **`sebool_use_nfs` / `sebool_use_cifs` are dead parameters.** They are declared
  on the base class (`init.pp`, documented El6-only and "will be removed")
  but `rsync::selinux` never reads them (`selinux.pp` only handles four
  booleans). Setting them does nothing on supported OSes.
- **The custom `rsync` type requires a timeout and forbids alias collisions.**
  Its `validate` raises if neither `timeout` nor `rsync_timeout` is set
  (`type/rsync.rb`) and if both members of an alias pair are supplied
  (`type/rsync.rb`); it also strips `protocol`/`user`/`password` when no
  server is given (`type/rsync.rb`). The Puppet defines always pass
  `rsync_timeout`, so this only bites hand-written `rsync {}` resources.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` appears only as a fixture
  (`.fixtures.yml`).
- **Several classes are `include`d but their modules are only optional/soft
  deps.** `rsync::server` `include`s `stunnel`, `iptables` (via
  `iptables::listen::tcp_stateful`), and `rsyslog`; `rsync::server::global`
  `include`s `tcpwrappers` and uses `vox_selinux::port`. `simp/stunnel`,
  `simp/rsyslog`, and `simp/vox_selinux` are declared runtime deps, but
  `iptables` and `tcpwrappers` are **not** in `metadata.json` — they are only
  reached on the non-stunnel/tcpwrappers code paths and are fixture-only.

## The `simp_options` / `simplib::lookup` seam

The SIMP feature-toggle seam. All calls live in `manifests/`; note the two
non-`simp_options` / no-default cases called out below.

| File | Key | `default_value` |
|------|-----|-----------------|
| `manifests/init.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/server.pp` | `simp_options::stunnel` | `true` |
| `manifests/server.pp` | `simp_options::firewall` | `false` |
| `manifests/server.pp` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `manifests/server.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/server/global.pp` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `manifests/server/global.pp` | `simp_options::tcpwrappers` | `false` |
| `manifests/server/section.pp` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `manifests/retrieve.pp` | `simp_options::rsync::server` | **none** (compile fails if unset) |
| `manifests/retrieve.pp` | `rsync::bwlimit` (module-local, not `simp_options`) | `undef` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/concat` `>= 6.4.0 < 10.0.0` (provides the `concat` /
  `concat::fragment` used to assemble `/etc/rsyncd.conf`)
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `ensure_resource`)
- `simp/rsyslog` `>= 7.6.0 < 10.0.0` (provides `rsyslog::rule::drop`, used when
  `$drop_rsyslog_noise`)
- `simp/simplib` `>= 4.9.0 < 6.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`, `simplib::passgen`, and the `Simplib::*` data
  types)
- `simp/stunnel` `>= 6.6.0 < 9.0.0` (provides `stunnel::connection`, the default
  server transport)
- `simp/vox_selinux` `>= 3.1.0 < 4.0.0` (provides `vox_selinux::port`)

No optional dependencies are declared (`metadata.json` has no
`simp.optional_dependencies` block).

Fixture-only dependencies (from `.fixtures.yml`, checked out for test
compilation, not runtime deps) include the runtime deps above plus `simp_options`,
`iptables`, `tcpwrappers`, `systemd`, `auditd`, `augeas_core`,
`augeasproviders_core`/`_grub`, `firewalld`/`simp_firewalld`, `haveged`,
`logrotate`, `pki`, `selinux_core`, and `simpcat`. Note `simp_options`,
`iptables`, and `tcpwrappers` are consumed by the manifests but are **not**
declared runtime dependencies.

Runtime requirement (from `metadata.json` `requirements`): `openvox >= 8.0.0
< 9.0.0`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the `rsync` base class (package, `/etc/rsync`, SELinux
  booleans).
- `manifests/selinux.pp` — internal `rsync::selinux` (four `selboolean`s).
- `manifests/server.pp` — the `rsync::server` class (daemon, stunnel/firewall,
  `concat` config, service, rsyslog noise drops).
- `manifests/server/global.pp` — private `rsync::server::global`
  (`assert_private()`; the global rsyncd.conf section, tcpwrappers, SELinux
  port).
- `manifests/server/section.pp` — the `rsync::server::section` define (one
  rsyncd share + secrets file).
- `manifests/retrieve.pp` — the `rsync::retrieve` define (client transfer entry
  point).
- `manifests/push.pp` — the `rsync::push` define (wrapper around `retrieve` with
  `pull => false`).
- `lib/puppet/type/rsync.rb` — the custom `rsync` resource type (aliased params,
  validation).
- `lib/puppet/provider/rsync/rsync.rb` — its provider (shells out to `rsync`;
  the transfer happens in the sync check).
- `templates/rsyncd.conf.global.erb`, `templates/rsyncd.conf.section.erb`,
  `templates/secrets.erb` — ERB templates for the config fragments and secrets
  file.
- `files/rsync.init` — SysV init script, used only on non-systemd systems.
- `data/common.yaml` — `rsync::server::package: rsync-daemon`.
- `data/os/Amazon-2.yaml` — overrides `rsync::server::package: rsync`.
- `hiera.yaml` — module data hierarchy (v5): OS name+major → OS name → OS family
  → kernel → common.
- `metadata.json` — deps, OS matrix, OpenVox requirement.
- `spec/classes/`, `spec/defines/` — rspec-puppet unit tests (`init_spec.rb`,
  `server_spec.rb`, `server/global_spec.rb`, `push_spec.rb`, `retrieve_spec.rb`,
  `server/section_spec.rb`).
- `spec/acceptance/suites/default/` — beaker acceptance suites (`00_default`,
  `10_server_client`, `20_server_client_stunnel`); `spec/acceptance/nodesets/`
  ships both vagrant nodesets (`almalinux`/`centos`/`oel`/`rhel`/`rocky` 8/9/10)
  and `docker_*` equivalents.
- `REFERENCE.md` — generated Puppet Strings reference.
- No `types/` directory — the module ships no Puppet 4.x data-type aliases of
  its own (the `Simplib::*` types come from `simp/simplib`); it does ship the
  Ruby `rsync` type/provider under `lib/`.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an
  `acceptance` job (`pr_tests.yml`) whose matrix nodes are
  `almalinux8`, `almalinux9`, and `almalinux10`. Its final step runs
  `bundle exec rake beaker:suites[default,<node>]` under
  `BEAKER_HYPERVISOR=vagrant_libvirt` (`pr_tests.yml`).

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/defines/retrieve_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite against an AlmaLinux node (as CI does)
bundle exec rake beaker:suites[default,almalinux9]
```

Relevant gem pins (from `Gemfile`): `simp-rake-helpers ~> 6.0`,
`simp-rspec-puppet-facts ~> 4.0.0`, `simp-beaker-helpers ~> 3.1`,
`rubocop ~> 1.85`. There is **no** `puppetlabs_spec_helper` pin — this module
has moved to the **voxpupuli-test** harness, so `spec/spec_helper.rb` uses
`require 'voxpupuli/test/spec_helper'` (`spec_helper.rb`). The test group
loads both `openvox` and `puppet` gems, defaulting to the `>= 8 < 9` range.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the classes and
  defines — they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing
  docs or parameters.
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` with an
  explicit default rather than assuming `simp_options` is included. (Note
  `retrieve.pp` intentionally omits a default for `simp_options::rsync::server`
  — that value is required.)
- Keep the daemon package name in module data (`data/*.yaml`), not hard-coded in
  the manifest, and keep using `ensure_resource` for it so the client and server
  can share one package resource.
- Keep `rsync::server::global` `assert_private()`'d — it is an internal
  implementation detail of `rsync::server`, not a public entry point.
- When adding config to `/etc/rsyncd.conf`, add a `concat::fragment` with an
  appropriate `order` (global is 5, sections are 10) rather than managing the
  file directly.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/`.
