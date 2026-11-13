# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 6.1 (`>= 6.1.0` in the gemspec; dummy GitHub tag `v6.7.0`)
- Oauth `>= 0.19.0` (dummy GitHub tag `v0.21.8`)
- Admin `>= 2.5.1` (dummy GitHub tag `v2.13.0`)
- Attachable `>= 0.22.0` (dummy GitHub tag `v0.23.0`)
- Accessible dummy tag `v0.32.0`, Trashable dummy tag `v0.14.0` (`require: false`), and Root Switchable dummy tag `v0.15.0`
- FlatPack dummy tag `v0.1.357`
- Recording Studio Dashboard dummy tag `v0.4.1` (not a gemspec dependency)
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
