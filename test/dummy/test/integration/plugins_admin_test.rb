# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "securerandom"
require "base64"

class PluginsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  MINI_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  )

  setup do
    @staff = create_user("staff")
    @workspace_admin = create_user("workspace-admin")
    @member = create_user("member")
    grant_staff!(@staff)
    workspace = Workspace.create!(name: "Z Admin Plugins #{SecureRandom.hex(3)}")
    @workspace_root = RecordingStudio.root_recording_for(workspace)
    Current.actor = @workspace_admin
    RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace_root, actor: @workspace_admin)
    RecordingStudioAccessible.grant_access(
      recording: @workspace_root,
      actor: @member,
      role: "view",
      manager_actor: @workspace_admin
    )
  end

  teardown do
    Current.actor = nil
  end

  test "view-only staff GET leaves plugin appearance counts unchanged" do
    viewer = create_user("staff-view")
    grant_staff!(viewer, role: "view")
    sign_in viewer
    Current.actor = viewer
    appearance_count = RecordingStudioPlugins::PluginAppearance.count
    recording_count = appearance_recording_count

    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_equal appearance_count, RecordingStudioPlugins::PluginAppearance.count
    assert_equal recording_count, appearance_recording_count
    assert_includes response.body, "WordPress"

    patch recording_studio_plugins.admin_plugins_path, params: {
      appearances: { wordpress: { name: "Should not save" } }
    }

    assert_response :forbidden
    assert_equal "WordPress", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:wordpress))

    delete recording_studio_plugins.admin_plugin_image_path(:wordpress)

    assert_response :forbidden
  end

  test "staff can open and edit plugin display names" do
    sign_in @staff
    Current.actor = @staff

    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_includes response.body, "Plugin names and pictures"
    assert_includes response.body, "WordPress"
    assert_select "input[name='appearances[wordpress][name]']"

    patch recording_studio_plugins.admin_plugins_path, params: {
      appearances: { wordpress: { name: "Press machine" } }
    }

    assert_redirected_to recording_studio_plugins.admin_plugins_path
    assert_equal :wordpress, RecordingStudioPlugins.find(:wordpress).key
    assert_equal "WordPress", RecordingStudioPlugins.find(:wordpress).name
    assert_equal "Press machine", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:wordpress))

    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Press machine"
    refute_includes response.body, ">WordPress<"

    get recording_studio_plugins.plugin_path(:wordpress)

    assert_response :success
    assert_includes response.body, "Press machine"

    sign_in @staff
    Current.actor = @staff
    patch recording_studio_plugins.admin_plugins_path, params: {
      appearances: { wordpress: { name: "" } }
    }

    follow_redirect!
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_includes response.body, "WordPress"
  end

  test "workspace admin and member cannot open the staff page" do
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    get recording_studio_plugins.admin_plugins_path

    assert_response :forbidden

    sign_in @member
    Current.actor = @member
    get recording_studio_plugins.admin_plugins_path

    assert_response :forbidden

    patch recording_studio_plugins.admin_plugins_path, params: {
      appearances: { wordpress: { name: "Nope" } }
    }

    assert_response :forbidden
    assert_equal "WordPress", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:wordpress))
  end

  test "unconfigured admin root shows an empty staff page" do
    sign_in @staff
    Current.actor = @staff
    config = RecordingStudioPlugins.configuration
    original_types = config.admin_root_types
    original_name = config.admin_root_name

    config.admin_root_types = []
    config.admin_root_name = nil
    RecordingStudioPlugins::Appearance.reset_index!

    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_select "h3", text: /Plugin names aren't wired up/
    refute_includes response.body, "WordPress"
    refute_includes response.body, "ChatGPT"
    assert_select "input[name='appearances[wordpress][name]']", count: 0
    assert_select "img", count: 0
  ensure
    config.admin_root_types = original_types
    config.admin_root_name = original_name
    RecordingStudioPlugins::Appearance.reset_index!
  end

  test "custom picture shows on directory detail and inbound modal and removing it falls back" do
    sign_in @staff
    Current.actor = @staff
    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_nil RecordingStudioPlugins::Appearance.recording_for(:chatgpt)

    patch recording_studio_plugins.admin_plugins_path, params: {
      appearances: { chatgpt: { name: "Chat helper" } }
    }

    recording = RecordingStudioPlugins::Appearance.recording_for(:chatgpt)
    assert recording
    result = RecordingStudioAttachable::Services::ImportAttachment.call(
      parent_recording: recording,
      io: StringIO.new(MINI_PNG),
      filename: "chatgpt.png",
      content_type: "image/png",
      actor: @staff,
      source: "direct_upload"
    )
    raise result.error if result.respond_to?(:failure?) && result.failure?

    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "img[alt='Chat helper']"
    assert_includes response.body, "Chat helper"
    assert_includes response.body, "plugin-chatgpt-people"
    assert_select "[id='plugin-chatgpt-people']" do
      assert_select "*", text: /Chat helper/
    end

    get recording_studio_plugins.plugin_path(:chatgpt)

    assert_response :success
    assert_select "img[alt='Chat helper']"
    refute_includes response.body, "flat-pack-shared-icon" if response.body.include?("Chat helper")

    sign_in @staff
    Current.actor = @staff
    delete recording_studio_plugins.admin_plugin_image_path(:chatgpt)

    assert_redirected_to recording_studio_plugins.admin_plugins_path
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "img[alt='Chat helper']", count: 0
    assert_includes response.body, "Chat helper"
  end

  private

  def create_user(label)
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def grant_staff!(user, role: "admin")
    recording = admin_root_recording
    manager = @staff || User.find_by(email: "admin@admin.com")
    Current.actor = manager || user
    if role.to_s == "admin"
      if manager && manager != user && RecordingStudioAccessible.authorized?(actor: manager, recording: recording, role: :admin)
        result = RecordingStudioAccessible.grant_access(
          recording: recording,
          actor: user,
          role: "admin",
          manager_actor: manager
        )
        raise result.error if result.respond_to?(:failure?) && result.failure?
      else
        RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
      end
      return
    end

    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: user,
      role: role,
      manager_actor: manager
    )
    raise result.error if result.respond_to?(:failure?) && result.failure?
  end

  def appearance_recording_count
    RecordingStudio::Recording.where(recordable_type: RecordingStudioPlugins::Appearance::RECORDABLE_TYPE).count
  end

  def admin_root_recording
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    RecordingStudio.root_recording_for(admin_root)
  end

  def switch_to_root!(root_recording)
    patch recording_studio_root_switchable.root_switch_path(scope: "all_workspaces"), params: {
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: recording_studio_plugins.root_path
      }
    }
    follow_redirect! if response.redirect?
  end
end
