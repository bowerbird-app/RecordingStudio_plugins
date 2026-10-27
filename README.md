# Recording Studio Plugins

A directory of integrations for Recording Studio.

Gems and host apps register plugins in Ruby. People browse them, read how to connect and use each one, and see a status the owning gem reports. This gem does not connect, authorize, import, or monitor an integration. Site staff can set a public display name and one picture per plugin; those are the only facts this gem stores.

## Install and mount

Add the gem and its runtime dependencies: Rails, `recording_studio` `>= 6.1.0`, `recording_studio_accessible`, `recording_studio_admin` `>= 2.5.1`, `recording_studio_attachable` `>= 0.22.0`, `recording_studio_oauth` `>= 0.19.0`, and `flat_pack` `>= 0.1.315`. Oauth is a hard dependency: installing Plugins also pulls Oauth's stack (Admin, API, Cache, Metrics, Site Settings, Trashable). Dummy and development Gemfiles pin Admin `v2.5.1`, the newest Admin tag that does not pull Logs. Attachable stores the optional plugin picture.

```ruby
gem "recording_studio_plugins"
```

```bash
bin/rails generate recording_studio_plugins:install
bin/rails generate recording_studio_plugins:migrations
bin/rails db:migrate
```

The generator mounts the engine at `/recording_studio_plugins`. Change the path with `--mount_path` or `config.mount_path`. Controllers call `recording_studio_layout { RecordingStudioPlugins.configuration.layout }`. `config.layout` is `nil` by default (the shared Recording Studio layout). Set it to a layout name, `false`, or `->(controller:) { ... }`. Headings come from `content_for :title` and `:subtitle`. Back uses `flat_pack_page_nav`.

People need access to the current workspace. The directory calls `RecordingStudioAccessible.authorized?(actor:, recording:, role: :view)`. A missing workspace or a failed check returns 403. Action links on plugins from `RecordingStudioPlugins.register` render when the same check passes for `:edit`. Root plugins from Oauth are listed only for workspace admins (`:admin`). A member who is not an admin does not see those rows. Connect and Disconnect post to Oauth. Oauth authorizes those requests.

Site staff set Plugin names and pictures on an Admin section. The index is a table of every registered plugin, with an Edit link per row. Each edit page holds the display name and the Attachable picture. That page is not a workspace setting. Workspace admins and members cannot open it. Access uses Admin's staff gate: Accessible on the admin root, plus the section's site blast radius. Add `RecordingStudioPlugins::PluginAppearance` to `recordable_types`, enable `section :plugins` on the admin root, mount Admin with `recording_studio_admin_for` and Attachable, set `config.admin_root_types` and `config.admin_root_name` (or `config.admin_recording_resolver`) to that staff admin root, and grant Accessible access on that admin root to staff only. There is no baked-in admin root name. Until the host sets that, the staff page is empty and the directory uses each plugin's registered name with no picture.

## Register

```ruby
RecordingStudioPlugins.register(
  :google_drive,
  name: "Google Drive",
  description: "Import images and files from Google Drive.",
  category: :storage,
  icon: "cloud",
  provider: MyApp::Plugins::GoogleDrive,
  position: 10,
  owner: "my_app"
)

RecordingStudioPlugins.find(:google_drive)        # Definition or nil
RecordingStudioPlugins.all                        # ordered Definitions, overrides applied
RecordingStudioPlugins.available(context:)        # all, minus hidden and unavailable
```

Metadata is `key`, `name`, `description`, `category`, `icon`, `provider`, `position`, `owner`, `kind`, and `setup_url`. `icon` is a Heroicon name. `category` must be a known category or registration raises `RecordingStudioPlugins::UnknownCategory`. `setup_url` is optional and must be `https` (the same `SafeUrl` check as other links, https only). Order is `position`, then `name`.

Registering the same key with the same `owner` replaces the definition, so reloads are safe. The same key with a different `owner` raises `RecordingStudioPlugins::RegistryConflict`.

Definitions hold no credentials. Display name overrides and pictures live in `recording_studio_plugin_appearances` (one current recording per plugin key under the admin root). The plugin key never changes. A blank display name falls back to the registered name. Removing the picture falls back to no picture.

Default categories are `ai_agents`, `storage`, `social`, `websites`, `automation`, and `other`. `config.extra_categories` adds more.

## Provider

A provider is any object that responds to some of these methods. Every method is optional. The controller passes a `RecordingStudioPlugins::Context` and the provider does not read `Current`.

| Method | Returns | When missing |
|---|---|---|
| `available?(context)` | `true` or `false` | listed |
| `status(context)` | `nil` or `RecordingStudioPlugins::Status` | no status, one Set up button with no URL |
| `about(context)` | plain text or `nil` | section hidden |
| `setup_instructions(context)` | plain text or `nil` | section hidden |
| `usage_instructions(context)` | plain text or `nil` | section hidden |
| `documentation_url(context)` | URL string or `nil` | no link |

```ruby
RecordingStudioPlugins::Context.new(actor:, root_recording:, request:)

RecordingStudioPlugins::Status.new(
  state: :connected,          # :connected, :attention, or nil
  message: nil,               # shown with Attention
  action_label: nil,          # for example "Connect", "Install", "Reconnect"
  action_url: nil
)
```

`request` is there so a future provider can read its own session key. This gem never reads or stores that session.

Each provider call is rescued and logged. If `available?` raises, the plugin is still listed. If `status` raises, that row shows no badge and no action. Other rows are unaffected. Each provider method is called at most once per plugin per request.

## Display

The directory is a two-column list of items. Each row is the display name on the left, and the status plus action on the right. When staff have set a picture, a small image sits next to the name (alt text is the display name). There is no search box or category filter. Inbound MCP client names open a modal that uses the same display name.

- On the directory, a missing Oauth connection is a primary Connect button. An active connection is a secondary Connected button that still posts Disconnect to Oauth.
- `state: :connected` shows a green badge reading "Connected".
- `state: :attention` shows an amber badge reading "Attention". An action renders when the provider supplies one.
- Otherwise there is no badge. One button uses `action_label` (default "Set up") and links to `action_url` when that URL is present.
- Inbound MCP clients (ChatGPT, Grok Bot) have no Oauth Connect or Disconnect. When you are connected, the row shows "Connected". It does not show "Not connected". Workspace admins see a people count under the name only when at least one person is connected. A Connect button appears when `setup_url` is an https URL. That button opens the setup URL. Clicking the name opens a modal. Admins get the connected-people list there (loaded when the modal opens). Other members do not get a count, a list, or that modal section. The modal people list is a lazy Turbo Frame and needs Turbo in the host. When a plugin has no picture, a small puzzle-piece placeholder sits before the name.
- There is no "Not connected" badge on other plugins.

This gem does not decide health, heartbeats, or staleness. The provider decides.

## URLs

Action and documentation URLs render as links. `https://` URLs and paths that start with a single `/` are allowed. `http:`, protocol-relative URLs, `javascript:`, `data:`, and URLs with userinfo are dropped. An invalid URL omits that control and the row still renders. External links open with `rel="noopener noreferrer"`.

Provider text is plain text. Rails escapes it.

## Configuration

`hidden_keys` and `overrides` apply when the directory reads, so a reload cannot wipe them. Overrides may set `name`, `description`, `category`, and `position`.

Oauth providers appear only when the host enables them **and** Oauth has them registered. Display name, description, category, and icon for Google Drive and Dropbox live in this gem. Oauth is never asked for names or icons.

```ruby
RecordingStudioPlugins.configure do |config|
  config.mount_path = "/recording_studio_plugins"
  config.hidden_keys = [:dropbox]
  config.overrides = { google_drive: { name: "Drive", position: 1 } }
  config.extra_categories = [:press]
  config.enabled_plugins = %i[google_drive dropbox]
  config.admin_root_types = ["AdminRoot"]
  config.admin_root_name = "Admin"
  config.actor_label = ->(person) { person&.name.presence || person&.email.presence || "User" }
end
```

Default `enabled_plugins` is empty. Nothing from Oauth outbound is listed until the host sets it. An enabled key that is not in `RecordingStudioOauth.outbound_providers` is skipped. Outbound providers with `kind: :root` appear for workspace admins. Inbound MCP clients are registered by the host (below), not through `enabled_plugins`.

`actor_label` names people on an inbound plugin's modal. The default is `name`, then `email`, then `"User"`. Those people load in one query per actor type when an admin opens the modal, not when the directory lists cards.

The host still registers the provider with Oauth:

```ruby
RecordingStudioGoogleDrive.register_oauth_provider
RecordingStudioDropbox.register_oauth_provider
```

## Inbound MCP clients

ChatGPT and Grok Bot connect from the client, not from this directory. The host registers them. This gem never writes Oauth `plugin_key`; staff set that on the registered app in Oauth admin.

```ruby
RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "https://help.example.com/chatgpt")
RecordingStudioPlugins.register_mcp_client(:grok_bot, setup_url: "https://help.example.com/grok")
```

Display name, description, category, and position come from `KnownProviders`, same as Google Drive and Dropbox. Status comes from `RecordingStudioOauth.inbound_connection_status` and `inbound_connections`, always for the current workspace.

## Root plugins and who sees what

Workspace members with `:view` can open the directory. Plugins from `RecordingStudioPlugins.register` stay visible to them, including inbound MCP clients (`kind: :user`).

Oauth providers with `kind: :root` (Google Drive and Dropbox as registered by those gems) are workspace plugins. Only a workspace admin sees them on the index. Non-admins never see workspace plugins or connected-people counts. Status does not carry across workspaces.

Connect, Reconnect, and Disconnect on those rows render only for workspace admins. They are real POST forms (Disconnect uses `_method=delete`) to Oauth, with CSRF, `owner=root`, `root_recording_id`, and `return_to` back to the directory. On the directory the connected control is labelled Connected and uses the secondary button style. Registered plugins that are not Oauth keep a plain action link.

Status for root plugins comes from `RecordingStudioOauth.combined_connection_status`. For a root provider only the `workspace` value is used: `:active` is Connected, `:needs_reconnect` is Attention with a reconnect message, `:missing` is not connected with Connect.

Inbound MCP clients use `McpClientStatus`: when that person is connected in this workspace the row says "Connected". It does not show "Not connected". Admins also see how many people are connected under the name when the count is at least one, and the modal lists name, role, app, connected since, and last used. Non-admins see only their own Connected state. Tokens never appear.

Oauth has no batch inbound status API. The directory calls `inbound_connection_status` once per inbound plugin (the same as listing status before). It does not call `inbound_connections` until an admin opens one plugin's modal.

This gem does not display or log tokens.

Copy ships under `recording_studio.plugins.*` through `RecordingStudio::Translation.register_shipped_english`, so a host can override it.

## Who owns what

| Gem | Owns |
|---|---|
| Recording Studio Plugins | Registry, directory page, staff names and pictures, status display, display names for known Oauth providers and inbound MCP clients |
| Recording Studio Attachable | Google Drive and Dropbox picking, import, and their OAuth. Tokens live in the Rails session, not on the workspace. |
| Recording Studio OAuth | Outbound provider registry, inbound plugin lookup, connection status, Connect and Disconnect routes, tokens |
| Recording Studio MCP | Remote MCP HTTP adapter over the OAuth grant. No installation or usage signal. |
| Recording Studio Accessible | Roles (`view`, `edit`, `admin`) and `authorized?` |
| Flatpack | UI components |

This gem depends on Rails, Recording Studio `>= 6.1.0`, `recording_studio_accessible`, Admin `>= 2.5.1`, Attachable `>= 0.22.0`, Oauth `>= 0.19.0`, and Flatpack `>= 0.1.315`. Oauth is hard: a host that adds Plugins also pulls Oauth's stack (Admin, API, Cache, Metrics, Site Settings, Trashable). Dummy and development Gemfiles pin Recording Studio `v6.1.0`, Oauth `v0.19.0`, Flatpack `v0.1.320`, Accessible `v0.22.0`, Admin `v2.5.1`, API `v0.14.0`, Attachable `v0.22.0`, Cache `v0.5.0`, Logs `v0.4.1` (API still needs it), Metrics `v0.5.0`, Site Settings `v0.2.0`, Trashable `v0.11.3`, and Root Switchable `v0.8.0`. Sibling gems that still declare Recording Studio below 6 need `test/support/widen_recording_studio_requirement.rb` before `bundle install`. Dummy lists Attachable Attachment, an AdminRoot, and PluginAppearance, and points plugin appearances at that AdminRoot.

## Another gem registering

This is a pattern, not shipped code. The other gem registers from its own engine. Use `to_prepare` for autoloaded provider classes and `after_initialize` for boot constants.

```ruby
config.to_prepare do
  next unless defined?(RecordingStudioPlugins)

  RecordingStudioPlugins.register(
    :dropbox,
    name: "Dropbox",
    description: "Import images and files from Dropbox.",
    category: :storage,
    icon: "archive-box",
    provider: RecordingStudioAttachable::Plugins::Dropbox,
    position: 20,
    owner: "recording_studio_attachable"
  )
end
```
