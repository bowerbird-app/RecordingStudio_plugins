# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 7 (`>= 7.0`, `< 8.0` in the gemspec; dummy GitHub tag `v7.0.0`)
- Oauth `>= 0.22.0`, `< 1.0` (dummy GitHub tag `v0.22.0`)
- Admin `>= 2.16.0` (dummy GitHub tag `v2.16.0`). Use `access_recording_resolver`. Admin 2.16 has no `site_admin_recording_resolver`.
- Accessible `admin_root_resolver` returns the same admin root. The plugins section's site blast radius needs it.
- Attachable `>= 0.28.0`, `< 1.0` (dummy GitHub tag `v0.28.0`)
- Accessible `>= 0.44.0`, `< 1.0` (dummy GitHub tag `v0.44.0`), Trashable dummy tag `v0.17.0` (`require: false`), and Root Switchable dummy tag `v0.16.0`
- API `v0.24.0`, Logs `v0.8.0`, Site Settings `v0.6.0`, Moveable `v5.0.0`, Metrics `v0.9.0`, Cache `v0.6.3`, Icons `v0.2.1`
- FlatPack dummy tag `v0.1.376`
- Recording Studio Dashboard dummy tag `v0.5.0` (not a gemspec dependency)
- Google Drive dummy tag `v0.6.1` and Dropbox dummy tag `v0.5.1` (not gemspec dependencies)
- Puma `>= 8.1.0` and msgpack `>= 1.8.7` in the dummy app
- Create roots with `RecordingStudio.create_root_recording!(recordable, actor:)`. `root_recording_for` only finds a root.
- The dummy `authorize_write` callback allows every write. `allow_unauthorized_writes` stays on so a missing actor can still record.
- Events need `root_recording_id` (`add_root_recording_id_to_recording_studio_events`). The dummy migration is already present.
- Public RubyGems and GitHub access for dependency installation

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
