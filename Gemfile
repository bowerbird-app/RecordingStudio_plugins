# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_plugins.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.213"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.7.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.18.0"
# TEMPORARY: re-pin to tag v0.18.0 after Oauth #69 is merged and tagged.
# https://github.com/bowerbird-app/RecordingStudio_Oauth/pull/69
gem "recording_studio_oauth", github: "bowerbird-app/RecordingStudio_Oauth",
                              branch: "cursor/inbound-plugin-key-e105"
# Required by oauth 0.17.0 (GitHub-only; not on RubyGems).
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.2.0"
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "v0.16.0"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.21.1"
gem "recording_studio_cache", github: "bowerbird-app/RecordingStudio_cache", tag: "v0.5.0"
gem "recording_studio_logs", github: "bowerbird-app/RecordingStudio_logs", tag: "v0.4.1"
gem "recording_studio_site_settings", github: "bowerbird-app/RecordingStudio_site_settings", tag: "v0.2.0"
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.11.3", require: false
# Required by trashable (GitHub-only; not on RubyGems).
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.6.1", require: false

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
