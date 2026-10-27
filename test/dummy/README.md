# Dummy App

This Rails app exists to validate the Recording Studio addon template in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Recording Studio default layout with a dummy left sidebar, the root switcher in the sidebar footer and signed-in top nav, FlatPack assets, and Tailwind source scanning
- Attachable Attachment in `recordable_types`; dummy override of Root Switchable's switch page for Flatpack 0.1.320; dummy maps Admin 2.5.1 `recording_studio_page_nav` onto `flat_pack_page_nav`
- Admin root at `/admin` for staff plugin names and pictures (`section :plugins`)
- Mounted `RecordingStudio::Engine` route behavior inside a host app
- Dummy registers ChatGPT and Grok Bot with `RecordingStudioPlugins.register_mcp_client`
- Dummy-only `/docs/*` pages for gem-specific onboarding

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with the seeded site staff user `admin@admin.com`. The seeded staff password is in `test/dummy/db/seeds.rb`. Switch to the "Admin" root in the root switcher. Open `/admin` (Plugins section) or `/recording_studio_plugins/admin/plugins`, then Edit a row. Those staff plugin pages use a dummy-only blank layout (no sidebar) with the same padded Flatpack `PageLayout` (`width: :default`) as other dummy product pages; the root switcher stays in the top bar.

## Useful Routes

- `/` - dummy app home page and template guidance
- `/admin` - staff plugin names and pictures after switching to the "Admin" root (site staff only)
- `/recording_studio_plugins/admin/plugins` - the same editor on the Plugins engine after switching to the Admin root
- `/fake_oauth/authorize` - dummy-only Google Drive and Dropbox authorize endpoint. Connect posts to Oauth, this issues a code, Oauth exchanges it, and the directory shows Connected. Token and revoke live at `/fake_oauth/token` and `/fake_oauth/revoke`. Tests and CI use the fake clients. Local real apps can set `google_drive` / `dropbox` (or `attachable.google_drive` / `attachable.dropbox`) in credentials, or the matching `GOOGLE_DRIVE_*` / `DROPBOX_*` env names.
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the generated addon experience before renaming the gem or copying patterns into another host app. If a layout, route, asset source, or Recording Studio initializer change breaks here, the template likely needs adjustment before reuse.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`. Replace dummy docs page content so it matches the gem's actual concepts.

The home page in `app/views/home/index.html.erb` should stay a minimal demo surface for the gem's core feature. Do not turn it into a wall of documentation; the dummy docs pages exist so deeper explanations can live in focused sections.
