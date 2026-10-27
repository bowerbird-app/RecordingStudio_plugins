# frozen_string_literal: true

require "test_helper"

class McpClientStatusTest < Minitest::Test
  def test_connected_maps_to_connected_status_without_count_for_members
    status = status_for(connected: true, connected_count: nil)

    assert status.connected?
    refute status.attention?
    assert_nil status.message
    assert_nil status.action_url
  end

  def test_not_connected_maps_to_existing_status_without_a_button
    status = status_for(connected: false, connected_count: nil)

    refute status.connected?
    refute status.attention?
    assert_nil status.message
    assert_nil status.action_label
    assert_nil status.action_url
  end

  def test_admin_count_is_status_message
    status = status_for(connected: true, connected_count: 3)

    assert status.connected?
    assert_equal "3 people connected", status.message
  end

  def test_admin_count_is_omitted_when_nil
    status = status_for(connected: false, connected_count: nil)

    assert_nil status.message
  end

  def test_admin_count_is_omitted_when_zero
    status = status_for(connected: false, connected_count: 0)

    assert_nil status.message
  end

  def test_one_person_connected_uses_singular_copy
    status = status_for(connected: true, connected_count: 1)

    assert_equal "1 person connected", status.message
  end

  def test_always_passes_the_current_root
    seen = nil
    root = Object.new
    actor = Object.new
    payload = { connected: false, connected_count: nil }
    lookup = lambda do |plugin_key:, root:, actor:|
      seen = { plugin_key: plugin_key, root: root, actor: actor }
      payload
    end

    RecordingStudioPlugins::McpClientStatus.stub(:connection_status, lookup) do
      RecordingStudioPlugins::McpClientStatus.new(:chatgpt).status(
        RecordingStudioPlugins::Context.new(actor: actor, root_recording: root)
      )
    end

    assert_equal :chatgpt, seen[:plugin_key]
    assert_same root, seen[:root]
    assert_same actor, seen[:actor]
  end

  private

  def status_for(connected:, connected_count:)
    payload = { connected: connected, connected_count: connected_count }
    RecordingStudioPlugins::McpClientStatus.stub(:connection_status, ->(**_) { payload }) do
      RecordingStudioPlugins::McpClientStatus.new(:chatgpt).status(
        RecordingStudioPlugins::Context.new(actor: :member, root_recording: :root)
      )
    end
  end
end
