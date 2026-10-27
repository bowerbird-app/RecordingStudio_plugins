# frozen_string_literal: true

require "test_helper"

class AppearanceTest < Minitest::Test
  def setup
    RecordingStudioPlugins.clear!
  end

  def teardown
    RecordingStudioPlugins.clear!
  end

  def test_display_name_falls_back_when_recordings_are_not_ready
    definition = RecordingStudioPlugins.register(
      :sample,
      name: "Sample",
      category: :other,
      position: 1,
      owner: "test"
    )

    RecordingStudioPlugins::Appearance.stub(:recordings_ready?, false) do
      assert_equal "Sample", RecordingStudioPlugins::Appearance.display_name(definition)
      assert_nil RecordingStudioPlugins::Appearance.image_url(definition)
      assert_nil RecordingStudioPlugins::Appearance.recording_for(:sample)
      assert_nil RecordingStudioPlugins::Appearance.ensure_recording!(:sample, actor: Object.new)
    end
  end

  def test_admin_plugins_path_is_defined
    assert_respond_to RecordingStudioPlugins, :admin_plugins_path
  end
end
