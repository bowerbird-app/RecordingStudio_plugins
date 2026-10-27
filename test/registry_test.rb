# frozen_string_literal: true

require "test_helper"

class RegistryTest < Minitest::Test
  def setup
    @configuration = RecordingStudioPlugins.configuration
    @original = {
      hidden_keys: @configuration.hidden_keys,
      overrides: @configuration.overrides,
      extra_categories: @configuration.extra_categories
    }
    RecordingStudioPlugins.clear!
  end

  def teardown
    RecordingStudioPlugins.clear!
    @configuration.hidden_keys = @original[:hidden_keys]
    @configuration.overrides = @original[:overrides]
    @configuration.extra_categories = @original[:extra_categories]
  end

  def test_register_and_find
    register(:google_drive, owner: "my_app", name: "Google Drive")

    definition = RecordingStudioPlugins.find(:google_drive)

    assert_equal "Google Drive", definition.name
    assert_equal "my_app", definition.owner
    assert_nil RecordingStudioPlugins.find(:missing)
  end

  def test_orders_by_position_then_name
    register(:later, owner: "my_app", name: "Zebra", position: 2)
    register(:early, owner: "my_app", name: "Alpha", position: 1)
    register(:tied, owner: "my_app", name: "Middle", position: 2)

    assert_equal %i[early tied later], RecordingStudioPlugins.all.map(&:key)
  end

  def test_unknown_category_raises
    error = assert_raises(RecordingStudioPlugins::UnknownCategory) do
      register(:nope, owner: "my_app", category: :press)
    end

    assert_includes error.message, "press"
  end

  def test_extra_category_can_be_registered
    @configuration.extra_categories = [:press]

    register(:paper, owner: "my_app", category: :press, name: "Paper")

    assert_equal :press, RecordingStudioPlugins.find(:paper).category
  end

  def test_same_owner_replaces_and_running_twice_keeps_one_entry
    2.times do
      register(:dropbox, owner: "recording_studio_attachable", name: "Dropbox", position: 5)
    end
    register(:dropbox, owner: "recording_studio_attachable", name: "Dropbox files", position: 4)

    matches = RecordingStudioPlugins.all.select { |definition| definition.key == :dropbox }

    assert_equal 1, matches.size
    assert_equal "Dropbox files", matches.first.name
    assert_equal 4, matches.first.position
  end

  def test_different_owner_raises_and_keeps_the_original
    register(:google_drive, owner: "my_app", name: "Google Drive")

    assert_raises(RecordingStudioPlugins::RegistryConflict) do
      register(:google_drive, owner: "other_app", name: "Drive")
    end

    assert_equal "my_app", RecordingStudioPlugins.find(:google_drive).owner
    assert_equal "Google Drive", RecordingStudioPlugins.find(:google_drive).name
  end

  def test_setup_url_must_be_https
    error = assert_raises(ArgumentError) do
      register(:docs, owner: "my_app", setup_url: "/relative")
    end

    assert_includes error.message, "https"

    register(:docs, owner: "my_app", setup_url: "https://example.com/docs")

    assert_equal "https://example.com/docs", RecordingStudioPlugins.find(:docs).setup_url
  end

  def test_override_ignores_kind_and_owner
    register(:google_drive, owner: "my_app", name: "Google Drive")
    definition = RecordingStudioPlugins.find(:google_drive)
    overridden = definition.override(kind: :root, owner: "other", name: "Drive")

    assert_equal "Drive", overridden.name
    assert_nil overridden.kind
    assert_equal "my_app", overridden.owner
  end

  def test_hidden_keys_and_overrides_survive_re_registration
    @configuration.hidden_keys = [:dropbox]
    @configuration.overrides = { google_drive: { name: "Drive", position: 1 } }
    register(:google_drive, owner: "my_app", name: "Google Drive", position: 10)
    register(:dropbox, owner: "my_app", name: "Dropbox", position: 20)
    register(:google_drive, owner: "my_app", name: "Google Drive", position: 10)

    assert_equal "Drive", RecordingStudioPlugins.find(:google_drive).name
    assert_equal 1, RecordingStudioPlugins.find(:google_drive).position
    assert_equal [:google_drive], RecordingStudioPlugins.available(context: empty_context).map(&:key)
  end

  private

  def register(key, owner:, **options)
    attributes = {
      name: key.to_s,
      description: "About #{key}",
      category: :storage,
      icon: "cloud",
      provider: Object.new,
      position: 10,
      owner: owner
    }.merge(options)
    RecordingStudioPlugins.register(key, **attributes)
  end

  def empty_context
    RecordingStudioPlugins::Context.new(actor: nil, root_recording: nil)
  end
end
