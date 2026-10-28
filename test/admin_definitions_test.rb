# frozen_string_literal: true

require "test_helper"

class AdminDefinitionsTest < Minitest::Test
  def test_plugins_section_is_site_staff_only
    section = RecordingStudioPlugins::Admin::PluginsSection

    assert_equal "plugins", section.key
    assert_equal :site, section.blast_radius
    RecordingStudioPlugins::Admin.register!
    assert_equal section, RecordingStudioAdmin.section_for("plugins")
  end
end
