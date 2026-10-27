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
    RecordingStudioPlugins::Appearance.reset_index!
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
    assert_includes response.body, "ChatGPT"

    get recording_studio_plugins.admin_plugin_edit_path(:chatgpt)

    assert_response :success
    assert_equal appearance_count, RecordingStudioPlugins::PluginAppearance.count
    assert_equal recording_count, appearance_recording_count

    patch recording_studio_plugins.admin_plugin_path(:chatgpt), params: {
      appearances: { chatgpt: { name: "Should not save" } }
    }

    assert_response :forbidden
    assert_equal "ChatGPT", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:chatgpt))

    delete recording_studio_plugins.admin_plugin_image_path(:chatgpt)

    assert_response :forbidden
  end

  test "staff can open and edit plugin display names" do
    sign_in @staff
    Current.actor = @staff

    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_includes response.body, "Plugin names and pictures"
    assert_select "[data-controller='recording-studio-root-switchable--root-switch-dropdown']"
    assert_select "[data-flat-pack--icon-name-value='puzzle-piece'][aria-hidden='true']"
    RecordingStudioPlugins.all.each do |definition|
      assert_includes response.body, RecordingStudioPlugins::Appearance.display_name(definition)
      assert_select "a[href=?]", recording_studio_plugins.admin_plugin_edit_path(definition.key), text: "Edit", count: 1
    end
    assert_select "input[name='appearances[chatgpt][name]']", count: 0

    get recording_studio_plugins.admin_plugin_edit_path(:chatgpt)

    assert_response :success
    assert_select "input[name='appearances[chatgpt][name]']"
    refute_includes response.body, "plugin-chatgpt-picture"

    patch recording_studio_plugins.admin_plugin_path(:chatgpt), params: {
      appearances: { chatgpt: { name: "Press machine" } }
    }

    assert_redirected_to recording_studio_plugins.admin_plugins_path
    assert_equal :chatgpt, RecordingStudioPlugins.find(:chatgpt).key
    assert_equal "ChatGPT", RecordingStudioPlugins.find(:chatgpt).name
    RecordingStudioPlugins::Appearance.reset_index!
    assert_equal "Press machine", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:chatgpt))

    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Press machine"
    refute_includes response.body, ">ChatGPT<"

    sign_in @staff
    Current.actor = @staff
    patch recording_studio_plugins.admin_plugin_path(:chatgpt), params: {
      appearances: { chatgpt: { name: "" } }
    }

    follow_redirect!
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_includes response.body, "ChatGPT"
  end

  test "staff can open /admin after switching to the Admin root" do
    sign_in @staff
    Current.actor = @staff
    switch_to_root!(admin_root_recording)

    get "/admin"

    assert_response :success
    assert_select "nav[aria-label='Plugins'] a[href='/recording_studio_plugins/admin/plugins']", count: 1
    assert_select "[data-controller='recording-studio-root-switchable--root-switch-dropdown']"

    get recording_studio_plugins.admin_plugins_path

    assert_response :success
    assert_select "nav[aria-label='Plugins'] a[href='/recording_studio_plugins/admin/plugins']", count: 1
  end

  test "staff get 403 on /admin from a workspace root" do
    sign_in @staff
    Current.actor = @staff
    switch_to_root!(@workspace_root)

    get "/admin"

    assert_response :forbidden
  end

  test "a later request does not keep the previous request's appearance names" do
    sign_in @staff
    Current.actor = @staff
    RecordingStudioPlugins::Appearance.update_name!(:chatgpt, name: "First press", actor: @staff)
    chatgpt = RecordingStudioPlugins.find(:chatgpt)

    assert_equal "First press", RecordingStudioPlugins::Appearance.display_name(chatgpt)

    appearance_id = RecordingStudioPlugins::Appearance.current_recordable(:chatgpt).id
    RecordingStudioPlugins::PluginAppearance.where(id: appearance_id).update_all(name: "Later press")

    assert_equal "First press", RecordingStudioPlugins::Appearance.display_name(chatgpt)

    RecordingStudioPlugins::Appearance::IndexState.reset

    assert_equal "Later press", RecordingStudioPlugins::Appearance.display_name(chatgpt)

    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Later press"
    refute_includes response.body, "First press"

    RecordingStudioPlugins::PluginAppearance.where(id: appearance_id).update_all(name: "Third press")

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Third press"
    refute_includes response.body, "Later press"
  end

  test "workspace admin and member cannot open the staff page" do
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    get recording_studio_plugins.admin_plugins_path

    assert_response :forbidden

    get recording_studio_plugins.admin_plugin_edit_path(:chatgpt)

    assert_response :forbidden

    sign_in @member
    Current.actor = @member
    get recording_studio_plugins.admin_plugins_path

    assert_response :forbidden

    patch recording_studio_plugins.admin_plugin_path(:chatgpt), params: {
      appearances: { chatgpt: { name: "Nope" } }
    }

    assert_response :forbidden
    assert_equal "ChatGPT", RecordingStudioPlugins::Appearance.display_name(RecordingStudioPlugins.find(:chatgpt))
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
    assert_select "input[name='appearances[chatgpt][name]']", count: 0
    assert_select "img", count: 0
  ensure
    config.admin_root_types = original_types
    config.admin_root_name = original_name
    RecordingStudioPlugins::Appearance.reset_index!
  end

  test "custom picture shows on directory detail and inbound modal and removing it falls back" do
    sign_in @staff
    Current.actor = @staff
    get recording_studio_plugins.admin_plugin_edit_path(:chatgpt)

    assert_response :success
    assert_nil RecordingStudioPlugins::Appearance.recording_for(:chatgpt)
    assert_select "input[name='appearances[chatgpt][name]']"

    patch recording_studio_plugins.admin_plugin_path(:chatgpt), params: {
      appearances: { chatgpt: { name: "Chat helper" } }
    }

    RecordingStudioPlugins::Appearance.reset_index!
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

    sign_in @staff
    Current.actor = @staff
    delete recording_studio_plugins.admin_plugin_image_path(:chatgpt)

    assert_redirected_to recording_studio_plugins.admin_plugin_edit_path(:chatgpt)
    sign_in @workspace_admin
    Current.actor = @workspace_admin
    switch_to_root!(@workspace_root)
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "img[alt='Chat helper']", count: 0
    assert_includes response.body, "Chat helper"
    assert_select "[data-flat-pack--icon-name-value='puzzle-piece'][aria-hidden='true']"
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
    manager = authorized_staff_manager(recording)
    Current.actor = manager || user

    if manager && (role.to_s != "admin" || manager != user)
      result = RecordingStudioAccessible.grant_access(
        recording: recording,
        actor: user,
        role: role,
        manager_actor: manager
      )
      raise result.error if result.respond_to?(:failure?) && result.failure?
      return
    end

    RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: user)
  end

  def authorized_staff_manager(recording)
    [User.find_by(email: "admin@admin.com"), @staff].compact.uniq.find do |actor|
      RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :admin)
    end
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
