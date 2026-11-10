# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "securerandom"

class PluginsDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(
      email: "dashboard-admin-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    @member = User.create!(
      email: "dashboard-member-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    workspace = Workspace.create!(name: "A Dashboard Workspace #{SecureRandom.hex(3)}")
    @root = RecordingStudio.root_recording_for(workspace)
    Current.actor = @admin
    RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @admin)
    RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: @member,
      role: "view",
      manager_actor: @admin
    )
  end

  teardown do
    Current.actor = nil
  end

  test "workspace admin sees a row of unconnected plugin cards" do
    sign_in_and_switch(@admin)

    get dashboard_path("plugins")

    assert_response :success
    assert_select "[data-dashboard=plugins] [data-dashboard-row=installable_plugins]"
    assert_select "[data-dashboard-placement=installable_plugins][data-dashboard-state=content]"
    assert_includes response.body, "Plugins you can connect"
    assert_includes response.body, "Google Drive"
    assert_includes response.body, "Dropbox"
    assert_includes response.body, "ChatGPT"
    assert_includes response.body, "Grok Bot"
    assert_select "[data-dashboard-placement=installable_plugins] a[href='/recording_studio_plugins/']",
                  minimum: 2
    assert_select "[data-dashboard-placement=installable_plugins] a[href='https://chatgpt.com']", text: "ChatGPT"
    assert_select "[data-dashboard-placement=installable_plugins] a[href='https://grok.com']", text: "Grok Bot"
    assert_select "[data-dashboard-placement=installable_plugins] [data-flat-pack--icon-name-value='puzzle-piece']"
  end

  test "member cards omit workspace plugins" do
    sign_in_and_switch(@member)

    get dashboard_path("plugins")

    assert_response :success
    assert_select "[data-dashboard-placement=installable_plugins][data-dashboard-state=content]"
    assert_includes response.body, "ChatGPT"
    assert_includes response.body, "Grok Bot"
    refute_includes response.body, "Google Drive"
    refute_includes response.body, "Dropbox"
  end

  test "empty state renders when nothing is left to connect" do
    sign_in_and_switch(@admin)
    RecordingStudioPlugins.configuration.hidden_keys = RecordingStudioPlugins.all.map(&:key)

    get dashboard_path("plugins")

    assert_response :success
    assert_select "[data-dashboard-placement=installable_plugins][data-dashboard-state=empty]"
    assert_includes response.body, "Nothing to connect right now."
    refute_includes response.body, "Google Drive"
  ensure
    RecordingStudioPlugins.configuration.hidden_keys = []
  end

  test "widget is omitted without directory view access" do
    stranger = User.create!(
      email: "dashboard-stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in stranger
    Current.actor = stranger

    get dashboard_path("plugins")

    assert_response :success
    assert_select "[data-dashboard-placement=installable_plugins]", count: 0
    refute_includes response.body, "Plugins you can connect"
  end

  private

  def sign_in_and_switch(user)
    sign_in user
    Current.actor = user
    switch_to_root!(@root)
  end

  def switch_to_root!(root_recording)
    patch recording_studio_root_switchable.root_switch_path(scope: "all_workspaces"), params: {
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: dashboard_path("plugins")
      }
    }
    follow_redirect! if response.redirect?
  end
end
