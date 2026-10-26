# frozen_string_literal: true

require "test_helper"

class BootTest < Minitest::Test
  def test_gemspec_depends_only_on_the_declared_gems
    spec = Gem::Specification.load(File.expand_path("../recording_studio_plugins.gemspec", __dir__))
    names = spec.runtime_dependencies.map(&:name).sort

    assert_equal %w[flat_pack rails recording_studio recording_studio_accessible recording_studio_oauth], names
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

    assert_includes changelog, "## [0.4.0]"
    assert_includes changelog, "There are no tables to migrate."
  end
end
