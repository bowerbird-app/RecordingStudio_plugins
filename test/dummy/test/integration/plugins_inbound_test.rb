# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "securerandom"

class PluginsInboundTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "inbound-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    workspace = Workspace.create!(name: "A Inbound Workspace #{SecureRandom.hex(3)}")
    @root = RecordingStudio.root_recording_for(workspace)
    Current.actor = @user
    RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    @access = access_recording_for(@root, @user)
    sign_in @user
  end

  teardown do
    Current.actor = nil
  end

  test "admin sees inbound rows with count and how to connect" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "a[href=?]", recording_studio_plugins.plugin_path(:chatgpt), text: "ChatGPT"
    assert_select "a[href=?]", "https://example.com/how-to-connect-chatgpt", text: "How to connect"
    assert_includes response.body, "Not connected"
    assert_includes response.body, "0 people connected"
    refute_select "form[action*='chatgpt']"
  end

  test "admin detail lists connected people and non-admin does not" do
    member = User.create!(
      email: "inbound-member-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    connect_chatgpt!(user: @user, access_recording: @access)
    RecordingStudioAccessible.grant_access(
      recording: @root,
      actor: member,
      role: "admin",
      manager_actor: @user
    )
    member_access = access_recording_for(@root, member)
    connect_chatgpt!(user: member, access_recording: member_access)

    get recording_studio_plugins.plugin_path(:chatgpt)

    assert_response :success
    assert_includes response.body, "Who&#39;s connected"
    assert_includes response.body, @user.email
    assert_includes response.body, member.email
    refute_includes response.body, "dummy-access-token"
    refute_includes response.body, "rsoauth_at_"

    viewer = User.create!(
      email: "inbound-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    RecordingStudioAccessible.grant_access(recording: @root, actor: viewer, role: "view", manager_actor: @user)
    sign_in viewer
    Current.actor = viewer

    get recording_studio_plugins.plugin_path(:chatgpt)

    assert_response :success
    refute_includes response.body, "Who's connected"
    refute_includes response.body, @user.email
    refute_includes response.body, member.email
    assert_includes response.body, "Not connected"
  end

  test "a person connected in one workspace is not connected in another" do
    connect_chatgpt!(user: @user, access_recording: @access)

    other_workspace = Workspace.create!(name: "B Inbound Workspace #{SecureRandom.hex(3)}")
    other_root = RecordingStudio.root_recording_for(other_workspace)
    RecordingStudioAccessible.bootstrap_owner_access!(recording: other_root, actor: @user)

    get recording_studio_plugins.root_path
    assert_includes chatgpt_row_text, "Connected"
    assert_includes chatgpt_row_text, "1 person connected"

    switch_to_root!(other_root)

    get recording_studio_plugins.root_path
    assert_includes chatgpt_row_text, "Not connected"
    refute_includes chatgpt_row_text, "1 person connected"
  end

  test "actor_label override is used on the people list" do
    connect_chatgpt!(user: @user, access_recording: @access)
    RecordingStudioPlugins.configuration.actor_label = ->(_actor) { "Workspace nickname" }

    get recording_studio_plugins.plugin_path(:chatgpt)

    assert_includes response.body, "Workspace nickname"
    refute_includes response.body, @user.email
  ensure
    RecordingStudioPlugins.configuration.actor_label = nil
  end

  private

  def connect_chatgpt!(user:, access_recording:)
    client, = chatgpt_client
    previous = Current.actor
    Current.actor = user
    result = RecordingStudioOauth::Services::CreateOauthAuthorization.call(
      oauth_client: client,
      manager_actor: user,
      access_recording: access_recording,
      role: "view",
      redirect_uri: "http://127.0.0.1/callback",
      code_challenge: challenge,
      code_challenge_method: "S256"
    )
    raise result.error unless result.success?

    authorization = result.value.fetch(:authorization)
    access_data = RecordingStudioOauth::AccessToken.generate
    refresh_data = RecordingStudioOauth::RefreshToken.generate
    RecordingStudioOauth::OauthAccessToken.create!(
      oauth_authorization: authorization,
      token_digest: access_data.fetch(:digest),
      token_prefix: access_data.fetch(:prefix),
      expires_at: 1.hour.from_now
    )
    RecordingStudioOauth::OauthRefreshToken.create!(
      oauth_authorization: authorization,
      token_digest: refresh_data.fetch(:digest),
      token_prefix: refresh_data.fetch(:prefix),
      expires_at: 30.days.from_now
    )
    result.value
  ensure
    Current.actor = previous
  end

  def chatgpt_row_text
    css_select("li[role='listitem']").map(&:text).find { |row| row.include?("ChatGPT") }.to_s
  end

  def access_recording_for(root, actor)
    RecordingStudioAccessible.access_recordings_for_actor(recording: root, actor: actor).first
  end

  def chatgpt_client
    existing = RecordingStudioOauth::OauthClient.find_by(plugin_key: "chatgpt")
    return [existing, nil] if existing

    RecordingStudioOauth::OauthClient.create!(
      name: "ChatGPT",
      confidential: false,
      redirect_uris: ["http://127.0.0.1/callback"],
      api_key: "public",
      plugin_key: "chatgpt"
    ).then { |client| [client, nil] }
  end

  def challenge
    verifier = "V#{SecureRandom.urlsafe_base64(32)}".ljust(43, "a")
    RecordingStudioOauth::Pkce.s256_challenge(verifier)
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
