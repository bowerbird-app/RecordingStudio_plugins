# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "securerandom"

class PluginsDirectoryTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "plugins-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    # Seed data is committed before the suite, and the dummy root switcher
    # defaults to the first workspace by name. This name stays first.
    workspace = Workspace.create!(name: "A Plugins Workspace #{SecureRandom.hex(3)}")
    @root = RecordingStudio.root_recording_for(workspace)
    Current.actor = @user
    RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    sign_in @user
  end

  teardown do
    Current.actor = nil
    restore_plugins!
  end

  test "directory renders the fixture plugins" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Plugins"
    assert_includes response.body, "Google Drive"
    assert_includes response.body, "Dropbox"
    assert_includes response.body, "WordPress"
    assert_includes response.body, "Grokbot"
    assert_includes response.body, "Website embed"
    assert_includes response.body, "Attention"
    assert_includes response.body, "Connect"
    assert_includes response.body, "Check connection"
    assert_includes response.body, "Install"
    assert_includes response.body, "Set up"
  end

  test "search is case insensitive across name description and category" do
    get recording_studio_plugins.root_path(q: "DRIVE")

    assert_response :success
    assert_includes response.body, "Google Drive"
    refute_includes response.body, "WordPress"

    get recording_studio_plugins.root_path(q: "storage")

    assert_includes response.body, "Dropbox"
    refute_includes response.body, "Grokbot"
  end

  test "category filter and the three empty states" do
    get recording_studio_plugins.root_path(category: "storage")

    assert_includes response.body, "Google Drive"
    refute_includes response.body, "WordPress"

    get recording_studio_plugins.root_path(category: "social")

    assert_includes response.body, "Nothing in this category"

    get recording_studio_plugins.root_path(q: "zzzz-no-plugin")

    assert_includes response.body, "No matches"

    RecordingStudioPlugins.clear!
    RecordingStudioPlugins.configuration.enabled_plugins = []
    get recording_studio_plugins.root_path

    assert_includes response.body, "Nothing here yet"
  end

  test "detail page shows provider text and escapes html" do
    register_plugin(:markup, provider: html_provider)

    get recording_studio_plugins.plugin_path(:wordpress)

    assert_response :success
    assert_includes response.body, "Attention"
    assert_includes response.body, "needs another look"
    assert_includes response.body, "Check connection"

    get recording_studio_plugins.plugin_path(:markup)

    assert_response :success
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    refute_includes response.body, "<script>alert(1)</script>"
  end

  test "unknown key is not found" do
    get recording_studio_plugins.plugin_path(:missing)

    assert_response :not_found
  end

  test "directory is forbidden without view access" do
    outsider = User.create!(
      email: "outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    sign_in outsider

    get recording_studio_plugins.root_path

    assert_response :forbidden
    assert_select "h3", "You don't have access"
  end

  test "missing root is forbidden" do
    Workspace.delete_all
    sign_in @user

    get recording_studio_plugins.root_path

    assert_response :forbidden
  end

  test "action links are hidden without edit access" do
    viewer = User.create!(
      email: "viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    RecordingStudioAccessible.grant_access(recording: @root, actor: viewer, role: "view", manager_actor: @user)
    sign_in viewer

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "needs another look"
    refute_includes response.body, "Google Drive"
    refute_includes response.body, "Dropbox"
    refute_includes response.body, ">Connect<"
    refute_includes response.body, ">Check connection<"
    refute_includes response.body, ">Set up<"
  end

  test "root plugin detail is not found without admin access" do
    viewer = User.create!(
      email: "viewer-show-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    RecordingStudioAccessible.grant_access(recording: @root, actor: viewer, role: "view", manager_actor: @user)
    sign_in viewer

    get recording_studio_plugins.plugin_path(:google_drive)

    assert_response :not_found
  end

  test "admin sees a connect action that posts to oauth with the workspace" do
    with_csrf_protection do
      get recording_studio_plugins.root_path

      assert_response :success
      assert_select "form[method='post'][action='/recording_studio_oauth/outbound/google_drive/connect']"
      assert_select "form[action='/recording_studio_oauth/outbound/google_drive/connect'] input[name='authenticity_token']"
      assert_select "input[name='owner'][value='root']"
      assert_select "input[name='root_recording_id'][value=?]", @root.id.to_s
      assert_select "input[name='return_to'][value=?]", recording_studio_plugins.root_path
      refute_includes response.body, 'data-method="post"'

      get recording_studio_plugins.plugin_path(:google_drive)

      assert_select "form[method='post'][action='/recording_studio_oauth/outbound/google_drive/connect']"
    end
  end

  test "admin sees a disconnect form for a live workspace connection" do
    connection = RecordingStudioOauth::OutboundConnection.create!(
      provider_key: "google_drive",
      root_recording_id: @root.id,
      connected_by: @user,
      access_token: "dummy-access-token",
      refresh_token: "dummy-refresh-token",
      status: "active",
      granted_scopes: ["files.read"]
    )

    with_csrf_protection do
      get recording_studio_plugins.root_path

      assert_response :success
      action = "/recording_studio_oauth/outbound/connections/#{connection.id}"
      assert_select "form[method='post'][action=?]", action
      assert_select "form[action=?] input[name='authenticity_token']", action
      assert_select "form[action=?] input[name='_method'][value='delete']", action
      assert_select "form[action=?] input[name='owner'][value='root']", action
      assert_select "form[action=?] input[name='root_recording_id'][value=?]", action, @root.id.to_s
      assert_select "form[action=?] input[name='return_to'][value=?]", action, recording_studio_plugins.root_path
      assert_includes response.body, "Disconnect"
    end
  end

  test "invalid action url is omitted and the card still renders" do
    register_plugin(:unsafe, provider: unsafe_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Unsafe"
    refute_includes response.body, "javascript:alert"
  end

  test "a raising status leaves the other cards rendered and each method runs once" do
    calls = Hash.new(0)
    register_plugin(:counted, provider: counting_provider(calls))
    register_plugin(:broken, name: "Broken plugin", provider: raising_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Broken plugin"
    assert_includes response.body, "WordPress"

    calls.each_key { |key| calls[key] = 0 }

    get recording_studio_plugins.plugin_path(:counted)

    assert_response :success
    assert_equal 1, calls[:available?]
    assert_equal 1, calls[:status]
    assert_equal 1, calls[:about]
    assert_equal 1, calls[:setup_instructions]
    assert_equal 1, calls[:usage_instructions]
    assert_equal 1, calls[:documentation_url]
  end

  private

  def with_csrf_protection
    was = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = was
  end

  def restore_plugins!
    configuration = RecordingStudioPlugins.configuration
    configuration.hidden_keys = []
    configuration.overrides = {}
    configuration.extra_categories = []
    configuration.enabled_plugins = []
    RecordingStudioPlugins.clear!
    RecordingStudioOauth::Outbound.reset_providers! if defined?(RecordingStudioOauth::Outbound)
    load Rails.root.join("config/initializers/recording_studio_plugins.rb")
  end

  def register_plugin(key, provider:, name: key.to_s.capitalize)
    RecordingStudioPlugins.register(
      key,
      name: name,
      description: "Extra plugin",
      category: :other,
      icon: "cloud",
      provider: provider,
      position: 90,
      owner: "test"
    )
  end

  def html_provider
    Class.new do
      def self.about(_context)
        "<script>alert(1)</script>"
      end
    end
  end

  def unsafe_provider
    Class.new do
      def self.status(_context)
        RecordingStudioPlugins::Status.new(action_label: "Connect", action_url: "javascript:alert(1)")
      end
    end
  end

  def raising_provider
    Class.new do
      def self.status(_context)
        raise "status failed"
      end
    end
  end

  def counting_provider(calls)
    Class.new do
      define_singleton_method(:available?) { |_context| calls[:available?] += 1; true }
      define_singleton_method(:status) do |_context|
        calls[:status] += 1
        RecordingStudioPlugins::Status.new(state: :connected)
      end
      define_singleton_method(:about) { |_context| calls[:about] += 1; "About counted" }
      define_singleton_method(:setup_instructions) { |_context| calls[:setup_instructions] += 1; "Connect counted" }
      define_singleton_method(:usage_instructions) { |_context| calls[:usage_instructions] += 1; "Use counted" }
      define_singleton_method(:documentation_url) { |_context| calls[:documentation_url] += 1; "https://example.com/counted" }
    end
  end
end
