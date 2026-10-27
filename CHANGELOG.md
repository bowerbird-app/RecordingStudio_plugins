# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2026-10-27

### Added
- Staff-only Admin section for plugin display names and one picture per registered plugin. The page lives on the admin root (`section :plugins`). Site staff with Accessible access on that root can open and edit it. Workspace admins and members cannot.
- `recording_studio_plugin_appearances` plus `recording_studio_plugins:migrations`. Each plugin key has a current appearance recording under the admin root. Attachable holds the optional picture (`max_file_count: 1`). Clearing the display name falls back to the registered name. Removing the picture falls back to no picture. The plugin key never changes.
- Directory and inbound modal use the display name. A custom picture renders next to the name with alt text equal to that name. Those pages load appearance recordings and pictures in one map per request.
- Appearance recordings are created when staff save a name or upload a picture, not when they open the staff list or a plugin's edit page.

### Changed
- **BREAKING:** this gem now depends on `recording_studio_admin >= 2.5.1` and `recording_studio_attachable >= 0.22.0`. Dummy and development GitHub tags stay on Admin `v2.5.1` (newest Admin without Logs) and Attachable `v0.22.0`. Logs `v0.4.1` stays because API `v0.14.0` still needs it.
- Dummy root switching lists workspace roots first, then the Admin root, so a workspace stays the default and staff can switch to Admin before opening `/admin`.
- Plugin appearance names and pictures are cached in `ActiveSupport::CurrentAttributes` for the current request or job. They are not stored on `Thread.current`.

### Upgrade notes
- Pin Admin `v2.5.1` and Attachable `v0.22.0` on this stack. Do not move Admin to `2.6`/`2.7` here (those tags add Logs).
- Run `bin/rails generate recording_studio_plugins:migrations` then `bin/rails db:migrate`.
- Add `RecordingStudioPlugins::PluginAppearance` to `recordable_types`. Enable `section :plugins` on the admin root. Mount Admin and Attachable. Set `config.admin_root_types` and `config.admin_root_name` (or `config.admin_recording_resolver`) to the host's staff admin root. This gem does not default those. Point Admin `access_recording_resolver` and `site_admin_recording_resolver` at that same recording. Grant Accessible access on that root to site staff only.
- Hosts that overrode directory, detail, or inbound modal markup should show the display name and the optional picture.
- Dummy (and hosts copying its switcher) must list the Admin root in `available_roots` after workspaces. Admin 2.5.1 `/admin` is 403 unless the current root is that Admin root.

## [0.6.0] - 2026-10-27

### Added
- Inbound MCP client plugins in the directory: ChatGPT and Grok Bot (`kind: :user`). Hosts register them with `RecordingStudioPlugins.register_mcp_client`. Status comes from Oauth `inbound_connection_status` / `inbound_connections`. There is no Connect or Disconnect on those rows. A "How to connect" link renders when `setup_url` is an https URL.
- Workspace admins see workspace plugins and inbound plugins. On the directory, the connected-people count sits under the plugin name. Clicking an inbound plugin opens a modal; the people list (name, role, app, connected since, last used) loads in that modal when it opens, and still on the detail page. Other members see inbound plugins with their own connected or not connected status. They do not see counts, connected-people names, the modal people section, or workspace plugins.
- `McpClientStatus` maps Oauth inbound answers onto the existing `Status` type. `setup_url` on registration is checked with `SafeUrl` (https only). `config.actor_label` names people on the list (default: name, then email, then "User"), loaded in one query per actor type when the modal or detail page asks.

### Changed
- **BREAKING:** `recording_studio >= 6.1.0` and `recording_studio_oauth >= 0.19.0`. Oauth 0.19.0 is the first release with `inbound_connection_status` / `inbound_connections` / `plugin_key`.
- Dummy and root GitHub tags: Recording Studio `v4.7.0` → `v6.1.0`, Flatpack `v0.1.213` → `v0.1.320`, Accessible `v0.18.0` → `v0.22.0`, Oauth `v0.19.0`, Admin `v2.2.0` → `v2.7.0`, API `v0.16.0` → `v0.14.0`, Attachable `v0.21.1` → `v0.15.0`, Metrics `v0.6.1` → `v0.5.0`. Cache `v0.5.0`, Logs `v0.4.1`, Site Settings `v0.2.0`, Trashable `v0.11.3` stay. Root Switchable `v0.9.0` → `v0.8.0` (same pin Oauth 0.19 uses; 0.9.0's switch page calls Flatpack APIs this stack does not have). Sibling gemspecs that still require Recording Studio below 6 are widened in `test/support/widen_recording_studio_requirement.rb`. Dummy lists Attachable Library and Placement, and overrides the Root Switchable switch page.
- `RecordingStudioPlugins.configuration.layout` is `nil` by default. Engine and dummy controllers call `recording_studio_layout`. Page headings come from `content_for :title` and `:subtitle`. Back uses `flat_pack_page_nav`.

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v6.1.0`, Oauth `v0.19.0`, Flatpack `v0.1.320`, and Accessible `v0.22.0`. Pin Admin `v2.7.0`, API `v0.14.0`, Attachable `v0.15.0`, and Metrics `v0.5.0` so the Oauth 0.19.0 stack resolves. API `v0.14.0` needs Metrics `< 0.6`.
- Replace `UsesDefaultLayout` / a hard-coded default layout with `recording_studio_layout { RecordingStudioPlugins.configuration.layout }`. Set `config.layout` to `nil`, a layout name, `false`, or `->(controller:) { ... }` (dummy uses the application layout for Devise).
- Set `content_for :title` (and `:subtitle` when you have one). Do not also render `FlatPack::PageTitle` for that same heading. Replace `recording_studio_page_nav` back arguments with `flat_pack_page_nav`.
- Run Oauth's migrations so registered apps have `plugin_key`. This gem still has no tables of its own.
- Register ChatGPT and Grok Bot in the host initializer. Staff set `plugin_key` on the Oauth app; this gem does not.
- There are no tables to migrate in this gem.

## [0.5.0] - 2026-10-26

### Removed
- **BREAKING:** `RecordingStudioPlugins::Catalog`, the directory search, the category filters and the `q`/`category` params, the details button, and the related locale keys. Hosts that override `plugins/index` or `_listing` markup need to update.
- The directory no longer shows plugin descriptions or the Attention message.

### Changed
- The plugins directory is a two-column list of items. Each row shows the plugin name on the left (no icon), and status plus action on the right. Connect and Connected are both secondary buttons. Connected still disconnects. Attention and Reconnect are unchanged. The name still opens the detail page, where Disconnect remains.

### Upgrade notes
- If you overrode `plugins/index` or `plugins/_listing`, match the list-item layout. Search and category filters are not on the directory anymore.
- `RecordingStudioPlugins::Catalog` is removed. Call `listings_for` if you were filtering through it.
- There are no tables to migrate.

## [0.4.0] - 2026-10-26

### Added
- Oauth root plugins in the directory. Hosts set `enabled_plugins` (default empty). The directory lists the intersection of that list and Oauth outbound providers with `kind: :root`.
- Built-in display names, descriptions, storage category, and icons for Google Drive and Dropbox. Host `overrides` still apply. Oauth is not asked for names or icons.
- Workspace admins see root plugins (`kind: :root`). Other workspace members do not, and the detail page 404s.
- Workspace connection status from `combined_connection_status`: connected, needs reconnect, or Connect. Connect and Disconnect are POST forms to Oauth (Disconnect uses `_method=delete`) with `owner=root`, `root_recording_id`, `return_to`, and a CSRF token.

### Changed
- **BREAKING:** `recording_studio_oauth >= 0.17.0` is a hard dependency. Hosts installing Plugins now also pull Oauth's stack (Admin, API, Cache, Metrics, Site Settings, Trashable) plus the pin bumps below.
- Dummy and root GitHub tags: Flatpack `v0.1.196` → `v0.1.213`, Trashable `v0.11.0` → `v0.11.3`, Metrics `v0.2.0` → `v0.6.1`. Oauth `v0.17.0` is pinned. Extra GitHub pins required to resolve Oauth: Admin `v2.2.0`, API `v0.16.0`, Attachable `v0.21.1`, Logs `v0.4.1`, Site Settings `v0.2.0`, and Cache `v0.5.0` on the root Gemfile. Attachable and Logs stay because they are GitHub-only transitives of Site Settings and API; Bundler cannot find them on RubyGems.

### Upgrade notes
- **BREAKING:** installing this gem now requires Oauth. Point host and dummy Gemfiles at Oauth `v0.17.0`, Flatpack `v0.1.213`, Trashable `v0.11.3`, and Metrics `v0.6.1`. Add the GitHub-only Oauth runtime gems Bundler cannot find on RubyGems (Admin, API, Cache, Metrics, Site Settings, Trashable).
- Set `config.enabled_plugins` for the Oauth providers this host should list. Register those providers with Oauth from the provider gem.
- Run Oauth's install and migrations on the host. This gem still has no tables of its own.
- Dummy registers `RecordingStudioApi::AdminApi` so CI eager-load can bootstrap Accessible grants. Hosts that already run Oauth's install already have this.
- There are no tables to migrate in this gem.

## [0.3.0] - 2026-10-22

### Added
- Plugin registry, directory, and detail page. Gems and hosts register plugins in Ruby. People browse them, read how to connect and use each one, and see a status the owning gem reports.
- Accessible `:view` gates the pages. Action links render for `:edit`.

### Upgrade notes
- This is the first plugins release. Add the gem, mount `RecordingStudioPlugins::Engine`, and register plugins.
- There are no tables to migrate.
- The directory does not connect, authorize, or store integration credentials. Owning gems report status through a provider.

## [Unreleased]

### Changed
- Dummy and root GitHub tags: Recording Studio `v4.2.1` → `v4.2.2`.

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.2`.

## [0.2.3] - 2026-10-01

### Changed
- Dummy and root GitHub tags: Recording Studio `v4.2.0` → `v4.2.1`, Accessible `v0.9.1` → `v0.10.1`, Root Switchable `v0.5.0` → `v0.5.1`, FlatPack `v0.1.177` → `v0.1.196`.
- Root and dummy lockfiles refreshed to current releases, including Rails `8.1.4`. The gem test suite requires `minitest-mock` because Minitest 6 moved `Object#stub` out of minitest.
- Dummy `image_processing` constraint `~> 1.2` → `~> 2.2`. `ruby-vips` is a direct dependency with `require: false`, because image_processing 2 treats the processor as optional and the app should boot before libvips is installed.
- Dummy schema includes the Accessible 0.10 `recording_studio_access_invitations` table.

### Fixed
- Dummy Tailwind now scans the installed FlatPack components and Recording Studio views. `tailwindcss:build` links those engines under `test/dummy/vendor/engines`, because git gems are checked out as `bundler/gems/<name>-<rev>` and the old `vendor/bundle/**/flatpack/` glob never matched.
- Dummy layouts load `flat_pack/application` (component CSS such as `.fp-button`) on both the Devise layout and the Recording Studio default layout.
- Dummy importmap pins `flat_pack/tiptap` and `flat_pack/local_time`, matching the FlatPack install contract.

### Upgrade notes
- Point host and dummy Gemfiles at Recording Studio `v4.2.1`, Accessible `v0.10.1`, Root Switchable `v0.5.1`, and FlatPack `v0.1.196`.
- Run `bin/rails generate recording_studio_accessible:migrations`, then `bin/rails db:migrate`, to add access invitations.
- Rebuild Tailwind after the FlatPack tag bump: `bin/rails tailwindcss:build`.
- Hosts still on `gem "image_processing", "~> 1.2"` should move to `~> 2.2` and add `gem "ruby-vips"` (or `gem "mini_magick"`).

## [0.2.2] - 2026-09-11

### Changed
- Gemspec `recording_studio` floor `~> 4.1` → `~> 4.2` so copied addons match Accessible 0.7+.
- Dummy Accessible tag `v0.6.0` → `v0.9.1`; FlatPack tag `v0.1.133` → `v0.1.177`. Recording Studio stays `v4.2.0`; Root Switchable stays `v0.5.0`.
- Root `Gemfile.lock` Rails `8.1.1` → `8.1.3.1` (with `json` `2.21.2`, `mail` `2.9.1`, `nokogiri` `1.19.4`) to match the dummy host lock and Active Storage CVE-2026-66066.
- Extra Cloud Agent skills now come from the plugin catalog (`skill-sources.json`) instead of a hardcoded extra URL. A missing or invalid catalog is skipped so Recording Studio skills still fetch. Failures still warn and exit 0.
- Docs and pin tests no longer mention `recording_studio/v3.0.0`, FlatPack `v0.1.133`, or Accessible `v0.6.0`.

### Added
- After skills, the Cloud Agent fetch hook lists plugin `*.mdc` rules from `RecordingStudio_cursor_plugin` into `.cursor/rules/` (gitignored, not packaged). A missing rules directory warns and skips. Failures still exit 0.
- Cloud Agent skill-fetch hook so copied addons load Recording Studio skills at Build time. `.cursor/environment.json` names the environment `recording-studio-gem-template`. `install` is `.cursor/install.sh`, which runs `.cursor/fetch-skills.sh` after provisioning. `snapshot` is omitted on purpose so Builds run install instead of reusing a laptop Personal snapshot. The script lists `recording-studio-*` skill ids from the public GitHub contents API and writes each `SKILL.md` into `.cursor/skills/` (gitignored, not packaged). Failures warn and still exit 0.
- Dummy Accessible migration for `depends_on_recording_id` (Accessible 0.8+).

### Upgrade notes
- Bump addon gemspecs to `spec.add_dependency "recording_studio", "~> 4.2"`.
- Point host/dummy Gemfiles at Accessible `v0.9.1` and FlatPack `v0.1.177` (Recording Studio tag stays `v4.2.0`).
- Run `bin/rails generate recording_studio_accessible:migrations` then `bin/rails db:migrate`. Do not hand-edit Accessible tables.
- Rebuild Tailwind after the FlatPack tag bump: `bin/rails tailwindcss:build`.
- Align root gem-suite `Gemfile.lock` Rails to `8.1.3.1` if it is still on `8.1.1`.

## [0.2.1] - 2026-09-01

### Added
- Full Cloud Agent development environment. `.cursor/install.sh` now provisions the whole stack at Build time on Cursor's default image — Ruby (pinned by `.ruby-version`), PostgreSQL 16, gem dependencies for both the gem and the dummy host app, the seeded dummy database, and compiled Tailwind/FlatPack CSS — then runs the existing `.cursor/fetch-skills.sh`. `snapshot` stays omitted so Builds run `install` as before.
- `.cursor/start.sh` per-boot hook that starts PostgreSQL and waits for readiness.
- `.cursor/environment.json` now declares `start` plus `rails-server` and `tailwind-watch` terminals and exposes port 3000, so a fresh Cloud Agent boots straight into a running, signed-in-ready dummy app.

### Notes
- The install script is idempotent; running it against a warm machine reuses the existing Ruby, packages, and gems.
- No gem runtime code changed. `.cursor/` files are excluded from the packaged gem.

## [0.2.0] - 2026-08-21

New addons copied from this template are born on Recording Studio 4.x.

### Added
- Gemspec dependency `recording_studio`, `~> 4.1`
- Dummy host wiring for Accessible (`enable_capability(:accessible, on: Workspace)`) and an opt-in `RecordingStudio::Capabilities::Example.to` mixin. `.to` wraps core 4.2.0 `include_for` (not a fourth verb, and not a raw `enable_capability` / `set_capability_options` path). Installing the gem does not enable the mixin globally; only dummy Workspace opts in.
- `bin/rename_gem` leftover-identity rewrite/verification for README, homepage, and changelog URLs that still say `RecordingStudioPlugins` or point at `bowerbird-app/recording_studio_plugins`

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated layout is Recording Studio's default layout plus FlatPack CSS/JS; Devise keeps its own sign-in layout
- Dummy app security pins: Rails `8.1.3.1`, `json` `2.21.2`, `mail` `2.9.1`, Brakeman `8.0.6`
- Require `RecordingStudio::Hooks` and `RecordingStudio::Services::BaseService` from core instead of shipping copies

### Removed
- Copied `lib/recording_studio_plugins/hooks.rb` and `lib/recording_studio_plugins/services/base_service.rb`
- Product-shipped `ExampleService`
- Custom `flat_pack_sidebar` authenticated shell

### Upgrade notes
- Point dummy or host Gemfiles at Recording Studio `v4.2.0` (not `recording_studio/v3.0.0`)
- Add `spec.add_dependency "recording_studio", "~> 4.1"` to addon gemspecs
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Delete any copied Hooks or BaseService files and require the core classes
- Keep recordable declarations; they are required, not a v3-only concern
- If Accessible is bundled, call `RecordingStudio.enable_capability(:accessible, on: Workspace)` (or your root type)

## [0.1.2] - 2026-07-21

### Changed
- Bumped the dummy app FlatPack dependency from `v0.1.33` to `v0.1.129`

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/recording_studio_plugins/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_plugins/releases/tag/v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_plugins/releases/tag/v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_plugins/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_plugins/releases/tag/v0.3.0
[0.2.3]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.2.3
[0.2.2]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.2.2
[0.2.1]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/recording_studio_plugins/releases/tag/v0.1.0
