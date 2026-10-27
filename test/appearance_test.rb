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

  def test_ensure_recording_returns_the_existing_recording_without_inserting
    existing = Object.new
    created = false

    RecordingStudioPlugins::Appearance.stub(:recording_for, ->(*) { existing }) do
      RecordingStudioPlugins::Appearance.stub(:create_recording!, ->(*) { created = true }) do
        assert_equal existing, RecordingStudioPlugins::Appearance.ensure_recording!(:sample, actor: Object.new)
        refute created
      end
    end
  end

  def test_ensure_recording_looks_up_again_after_a_plugin_key_unique_conflict
    existing = Object.new
    error = ActiveRecord::RecordNotUnique.new(
      "PG::UniqueViolation: duplicate key value violates unique constraint " \
      "\"index_recording_studio_plugin_appearances_on_plugin_key\""
    )
    lookups = 0
    lookup = lambda do |_key|
      lookups += 1
      lookups == 1 ? nil : existing
    end

    RecordingStudioPlugins::Appearance.stub(:recording_for, lookup) do
      RecordingStudioPlugins::Appearance.stub(:create_recording!, ->(*) { raise error }) do
        RecordingStudioPlugins::Appearance.stub(:reset_index!, -> {}) do
          assert_equal existing, RecordingStudioPlugins::Appearance.ensure_recording!(:sample, actor: Object.new)
        end
      end
    end
  end

  def test_ensure_recording_does_not_rescue_other_unique_conflicts
    error = ActiveRecord::RecordNotUnique.new(
      "PG::UniqueViolation: duplicate key value violates unique constraint \"other_index\""
    )

    RecordingStudioPlugins::Appearance.stub(:recording_for, ->(*) {}) do
      RecordingStudioPlugins::Appearance.stub(:create_recording!, ->(*) { raise error }) do
        raised = assert_raises(ActiveRecord::RecordNotUnique) do
          RecordingStudioPlugins::Appearance.ensure_recording!(:sample, actor: Object.new)
        end
        assert_equal error, raised
      end
    end
  end

  def test_update_name_treats_the_registered_name_as_no_custom_name
    RecordingStudioPlugins.register(
      :sample,
      name: "Sample",
      category: :other,
      position: 1,
      owner: "test"
    )
    recordable = Struct.new(:name).new("Press")
    recording = Struct.new(:recordable).new(recordable)
    revised = false

    RecordingStudioPlugins::Appearance.stub(:ensure_recording!, ->(*) { recording }) do
      RecordingStudioPlugins::Appearance.stub(:revise_name!, lambda { |*_args, **_kwargs|
        revised = true
        recordable.name = nil
        recording
      }) do
        RecordingStudioPlugins::Appearance.stub(:reset_index!, -> {}) do
          RecordingStudioPlugins::Appearance.update_name!(:sample, name: "Sample", actor: Object.new)
          RecordingStudioPlugins::Appearance.update_name!(:sample, name: "  Sample  ", actor: Object.new)
          RecordingStudioPlugins::Appearance.update_name!(:sample, name: "", actor: Object.new)
        end
      end
    end

    assert revised
    assert_nil recordable.name
  end

  def test_ensure_recording_inserts_when_no_recording_exists
    created = Object.new
    lookups = 0
    lookup = lambda do |_key|
      lookups += 1
      lookups == 1 ? nil : created
    end

    RecordingStudioPlugins::Appearance.stub(:recording_for, lookup) do
      RecordingStudioPlugins::Appearance.stub(:create_recording!, ->(*) { created }) do
        RecordingStudioPlugins::Appearance.stub(:reset_index!, -> {}) do
          assert_equal created, RecordingStudioPlugins::Appearance.ensure_recording!(:sample, actor: Object.new)
        end
      end
    end
  end
end
