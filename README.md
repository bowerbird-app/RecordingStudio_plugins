# Recording Studio Plugins

A directory of integrations for Recording Studio.

Gems and host apps register plugins in Ruby. People browse them, read how to connect and use each one, and see a status the owning gem reports. This gem does not connect, authorize, import, monitor, or store anything about an integration.

## Install and mount

Add the gem and its runtime dependencies: Rails, `recording_studio`, `recording_studio_accessible`, and `flat_pack`.

```ruby
gem "recording_studio_plugins"
```

```bash
bin/rails generate recording_studio_plugins:install
```

The generator mounts the engine at `/recording_studio_plugins`. Change the path with `--mount_path` or `config.mount_path`. The pages use Recording Studio's default layout.

People need access to the current workspace. Both pages call `RecordingStudioAccessible.authorized?(actor:, recording:, role: :view)`. A missing workspace or a failed check returns 403. Action links render only when the same check passes for `:edit`. This gem has no mutating endpoint. The destination gem authorizes its own requests.

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

Metadata is `key`, `name`, `description`, `category`, `icon`, `provider`, `position`, and `owner`. `icon` is a Heroicon name. `category` must be a known category or registration raises `RecordingStudioPlugins::UnknownCategory`. Order is `position`, then `name`.

Registering the same key with the same `owner` replaces the definition, so reloads are safe. The same key with a different `owner` raises `RecordingStudioPlugins::RegistryConflict`.

Definitions hold no credentials and create no records. There are no tables.

Default categories are `ai_agents`, `storage`, `social`, `websites`, `automation`, and `other`. `config.extra_categories` adds more. Labels come from `recording_studio.plugins.categories.*`.

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

Each provider call is rescued and logged. If `available?` raises, the plugin is still listed. If `status` raises, that card shows no badge and no action. Other cards are unaffected. Each provider method is called at most once per plugin per request.

## Display

- `state: :connected` shows a green badge reading "Connected".
- `state: :attention` shows an amber badge reading "Attention", plus `message`. An action renders when the provider supplies one.
- Otherwise there is no badge. One button uses `action_label` (default "Set up") and links to `action_url` when that URL is present.
- There is no "Not connected" badge.

This gem does not decide health, heartbeats, or staleness. The provider decides.

## URLs

Action and documentation URLs render as links. `https://` URLs and paths that start with a single `/` are allowed. `http:`, protocol-relative URLs, `javascript:`, `data:`, and URLs with userinfo are dropped. An invalid URL omits that control and the card still renders. External links open with `rel="noopener noreferrer"`.

Provider text is plain text. Rails escapes it.

## Configuration

`hidden_keys` and `overrides` apply when the directory reads, so a reload cannot wipe them. Overrides may set `name`, `description`, `category`, and `position`.

```ruby
RecordingStudioPlugins.configure do |config|
  config.mount_path = "/recording_studio_plugins"
  config.hidden_keys = [:dropbox]
  config.overrides = { google_drive: { name: "Drive", position: 1 } }
  config.extra_categories = [:press]
end
```

Copy ships under `recording_studio.plugins.*` through `RecordingStudio::Translation.register_shipped_english`, so a host can override it.

## Who owns what

| Gem | Owns |
|---|---|
| Recording Studio Plugins | Registry, directory page, detail page, status display |
| Recording Studio Attachable | Google Drive and Dropbox picking, import, and their OAuth. Tokens live in the Rails session, not on the workspace. |
| Recording Studio OAuth | Inbound authorization server for third-party apps connecting to the host. No outbound Google or Dropbox OAuth. |
| Recording Studio MCP | Remote MCP HTTP adapter over the OAuth grant. No installation or usage signal. |
| Recording Studio Accessible | Roles (`view`, `edit`, `admin`) and `authorized?` |
| Flatpack | UI components |

This gem depends on Rails, `recording_studio`, `recording_studio_accessible`, and `flat_pack` only.

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
