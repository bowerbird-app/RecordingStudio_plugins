# frozen_string_literal: true

require "test_helper"

class BootTest < Minitest::Test
  def test_gemspec_depends_only_on_the_declared_gems
    spec = Gem::Specification.load(File.expand_path("../recording_studio_plugins.gemspec", __dir__))
    names = spec.runtime_dependencies.map(&:name).sort

    assert_equal %w[
      flat_pack rails recording_studio recording_studio_accessible
      recording_studio_admin recording_studio_attachable recording_studio_oauth
    ].join(" ").split, names
  end

  def test_oauth_is_required_at_boot
    lib = File.read(File.expand_path("../lib/recording_studio_plugins.rb", __dir__))
    directory = File.read(File.expand_path("../lib/recording_studio_plugins/oauth_directory.rb", __dir__))

    assert_includes lib, 'require "recording_studio_oauth"'
    assert_includes lib, 'require "recording_studio_admin"'
    assert_includes lib, 'require "recording_studio_attachable"'
    refute_includes directory, "defined?(RecordingStudioOauth)"
  end

  def test_engine_boots_without_sibling_integration_gems
    assert_kind_of Class, RecordingStudioPlugins::Engine
    assert_operator RecordingStudioPlugins::Engine, :<, Rails::Engine
    assert defined?(RecordingStudioOauth)
    refute defined?(RecordingStudioMcp)
    refute Object.const_defined?(%w[Gem Template].join)
  end

  def test_changelog_records_upgrade_notes_for_this_version
    changelog = File.read(File.expand_path("../CHANGELOG.md", __dir__))

    assert_includes changelog, "## [0.7.0]"
    assert_includes changelog, "## [0.6.0]"
    assert_includes changelog, "recording_studio >= 6.1.0"
    assert_includes changelog, "recording_studio_oauth >= 0.19.0"
    refute_includes changelog, "cursor/inbound-plugin-key-e105"
    refute_includes changelog, "TEMPORARY"
    assert_includes changelog, "## [0.4.0]"
    assert_includes changelog, "There are no tables to migrate."
    assert_includes changelog, "**BREAKING:**"
    assert_includes changelog, "Oauth's stack (Admin, API, Cache, Metrics, Site Settings, Trashable)"
    assert_includes changelog, "compare/v0.7.0...HEAD"
    refute_includes changelog, "v4.2.1` → `v4.2.2"
    footer = changelog.lines.last(20).join
    refute_includes footer, "https://github.com/bowerbird-app/recording_studio_plugins"
    assert_includes footer, "https://github.com/bowerbird-app/RecordingStudio_plugins/compare/v0.7.0...HEAD"
  end
end
