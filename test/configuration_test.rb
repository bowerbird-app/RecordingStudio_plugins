# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioPlugins::Configuration.new
  end

  def test_defaults
    assert_equal "/recording_studio_plugins", @configuration.mount_path
    assert_empty @configuration.hidden_keys
    assert_empty @configuration.overrides
    assert_empty @configuration.extra_categories
    assert_equal %i[ai_agents storage social websites automation other], @configuration.categories
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(mount_path: "/plugins", hidden_keys: [:dropbox], extra_categories: [:press])

    assert_equal "/plugins", @configuration.mount_path
    assert_equal ["dropbox"], @configuration.hidden_keys
    assert_equal [:press], @configuration.extra_categories
    assert_includes @configuration.categories, :press
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", mount_path: "/plugins")

    refute_respond_to @configuration, :unknown_key
    assert_equal "/plugins", @configuration.mount_path
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original[:mount_path], @configuration.mount_path
    assert_equal original[:hidden_keys], @configuration.hidden_keys
    assert_equal original[:extra_categories], @configuration.extra_categories
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("mount_path" => "/string", "hidden_keys" => ["dropbox"])

    assert_equal "/string", @configuration.mount_path
    assert_equal ["dropbox"], @configuration.hidden_keys
    assert @configuration.hidden?(:dropbox)
  end

  def test_overrides_keep_allowed_keys_only
    @configuration.overrides = {
      google_drive: { name: "Drive", description: "Files", category: "storage", position: "1", icon: "nope" }
    }

    assert_equal(
      { "google_drive" => { name: "Drive", description: "Files", category: :storage, position: 1 } },
      @configuration.overrides
    )
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioPlugins.configure

    assert_kind_of RecordingStudioPlugins::Configuration, RecordingStudioPlugins.configuration
  end
end
