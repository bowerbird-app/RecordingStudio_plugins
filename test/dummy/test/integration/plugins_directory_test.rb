# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "securerandom"
require "uri"

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
    switch_to_root!(@root)
    FakeOauth.reset!
    FakeDropboxOauth.reset!
  end

  teardown do
    Current.actor = nil
    FakeOauth.reset!
    FakeDropboxOauth.reset!
    restore_plugins!
  end

  test "directory renders plugins as two-column list items" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Plugins"
    assert_select ".fp-page-layout[data-fp-page-layout-width='default']"
    refute_select "[data-fp-page-layout-width='full']"
    assert_select "div[class*='grid'][class*='grid-cols-1'][class*='md:grid-cols-2']"
    assert_select "ul[role='list'][class*='flat-pack-list']"
    assert_select "li[role='listitem']"
    assert_select "button[data-modal-id=?]", "plugin-chatgpt-people", text: "ChatGPT"
    assert_select "button[data-modal-id=?]", "plugin-grok_bot-people", text: "Grok Bot"
    assert_includes response.body, "Google Drive"
    assert_includes response.body, "Dropbox"
    refute_includes response.body, "WordPress"
    refute_includes response.body, "Website embed"
    refute_includes response.body, "Grokbot"
    assert_includes response.body, "Connect"
    assert_select "nav[aria-label='Plugins'] a[href='/recording_studio_plugins/']", count: 1
    assert_select "nav[aria-label='Plugins'] a[href='/recording_studio_plugins/admin/plugins']", count: 0
    %w[ChatGPT Grok\ Bot Google\ Drive Dropbox].each do |name|
      assert_equal 1, directory_rows.count { |row| row.include?(name) }, "#{name} should appear once"
    end
    assert_select "li[role='listitem'] .flat-pack-list-item-icon", count: 0
    assert_select "li[role='listitem'][class*='items-center']"
    assert_select "li[role='listitem'] [class*='h-10'][class*='w-10']"
    assert_select "a[href='https://chatgpt.com'][target='_blank']", text: "Connect"
    assert_select "a[href='https://grok.com'][target='_blank']", text: "Connect"
    assert_select "form[action='/recording_studio_oauth/outbound/google_drive/connect']"
    assert_select "form[action='/recording_studio_oauth/outbound/dropbox/connect']"
    assert_select "input[name='q']", count: 0
    assert_select "a[href*='category=']", count: 0
    assert_select "[data-flat-pack--icon-name-value='puzzle-piece'][aria-hidden='true']"
    assert_includes response.body, @root.recordable.name
    assert_select "[data-controller='recording-studio-root-switchable--root-switch-dropdown']"
    assert_select ".fp-page-layout[data-fp-page-layout-width=default]"
    refute_select "[data-fp-page-layout-width=full]"
    assert_directory_apostrophes
    refute_includes response.body, "Not connected"
    refute_includes response.body, "0 people connected"
  end

  test "directory subtitle uses a real apostrophe" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_directory_apostrophes
  end

  test "directory escapes a locale value that contains a script tag" do
    I18n.backend.store_translations(
      :en,
      recording_studio: { plugins: { directory: { title: "<script>alert(1)</script>" } } }
    )

    get recording_studio_plugins.root_path

    assert_response :success
    refute_includes response.body, "<script>alert(1)</script>"
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
  ensure
    I18n.backend.store_translations(
      :en,
      recording_studio: { plugins: { directory: { title: "Plugins" } } }
    )
  end

  test "non-root connected plugin still shows the Connected badge" do
    register_plugin(:linked, name: "Linked plugin", provider: connected_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Linked plugin"
    assert_select "li[role='listitem']", text: /Linked plugin/ do
      assert_select "*", text: "Connected"
    end
  end

  test "search and category params do not hide plugins" do
    get recording_studio_plugins.root_path(q: "DRIVE", category: "storage")

    assert_response :success
    assert_includes response.body, "Google Drive"
    assert_includes response.body, "ChatGPT"
    assert_includes response.body, "Grok Bot"
  end

  test "directory appearance queries do not grow with plugin count" do
    5.times do |index|
      register_plugin(:"batch_a_#{index}", provider: Object.new, name: "Batch A #{index}")
    end
    few = count_directory_queries

    assert_response :success

    8.times do |index|
      register_plugin(:"batch_b_#{index}", provider: Object.new, name: "Batch B #{index}")
    end
    many = count_directory_queries

    assert_response :success
    assert_equal few, many
  end

  test "empty directory shows the empty state" do
    RecordingStudioPlugins.clear!
    RecordingStudioPlugins.configuration.enabled_plugins = []
    get recording_studio_plugins.root_path

    assert_includes response.body, "Nothing here yet"
    assert_includes response.body, "Plugins show up here once they're added."
    refute_includes response.body, "&#39;"
    refute_includes response.body, "&amp;#39;"
    assert_select "li[role='listitem']", count: 0
  end

  test "directory names are escaped" do
    register_plugin(:markup, name: "<script>alert(1)</script>", provider: html_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    refute_includes response.body, "<script>alert(1)</script>"
  end

  test "removed detail pages are not found" do
    get "/recording_studio_plugins/chatgpt"

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
    assert_includes response.body, "You don't have access"
    refute_includes response.body, "&#39;"
    refute_includes response.body, "&amp;#39;"
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
    switch_to_root!(@root)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "ChatGPT"
    assert_includes response.body, "Grok Bot"
    refute_includes response.body, "Not connected"
    refute_includes response.body, "people connected"
    refute_includes response.body, "Google Drive"
    refute_includes response.body, "Dropbox"
    refute_includes response.body, ">Check connection<"
    refute_includes response.body, ">Set up<"
  end

  test "root plugins are hidden without admin access" do
    viewer = User.create!(
      email: "viewer-show-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    RecordingStudioAccessible.grant_access(recording: @root, actor: viewer, role: "view", manager_actor: @user)
    sign_in viewer
    switch_to_root!(@root)

    get recording_studio_plugins.root_path

    assert_response :success
    refute_includes response.body, "Google Drive"
  end

  test "dummy google drive and dropbox connect through oauth" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "form[method='post'][action='/recording_studio_oauth/outbound/google_drive/connect']"
    assert_select "form[method='post'][action='/recording_studio_oauth/outbound/dropbox/connect']"
    refute_select "a[href='/recording_studio_oauth/outbound/google_drive/connect']"
    refute_select "a[href='/recording_studio_oauth/outbound/dropbox/connect']"
    refute_select "a[href='#']", text: "Connect"
  end

  test "dummy google drive and dropbox connect forms skip turbo" do
    get recording_studio_plugins.root_path

    assert_response :success
    assert_select "form[method='post'][action='/recording_studio_oauth/outbound/google_drive/connect'][data-turbo='false']"
    assert_select "form[method='post'][action='/recording_studio_oauth/outbound/dropbox/connect'][data-turbo='false']"
  end

  test "google drive connect follows fake authorize then shows connected on the directory" do
    follow_dummy_connect!(provider: "google_drive")

    assert_equal recording_studio_plugins.root_path, request.path
    assert_select "li[role='listitem']", text: /Google Drive/ do
      assert_select "*", text: "Connected"
      assert_select "form[method='post'] button", text: "Connected"
      refute_select "form[action='/recording_studio_oauth/outbound/google_drive/connect']"
    end
    connection = RecordingStudioOauth::OutboundConnection.find_by!(
      provider_key: "google_drive",
      root_recording_id: @root.id
    )
    assert_equal "active", connection.status
    assert_equal "acct-demo", connection.external_account_id
    assert connection.access_token.present?
  end

  test "dropbox connect follows fake authorize then shows connected on the directory" do
    follow_dummy_connect!(provider: "dropbox")

    assert_equal recording_studio_plugins.root_path, request.path
    assert_select "li[role='listitem']", text: /Dropbox/ do
      assert_select "*", text: "Connected"
      assert_select "form[method='post'] button", text: "Connected"
      refute_select "form[action='/recording_studio_oauth/outbound/dropbox/connect']"
    end
    connection = RecordingStudioOauth::OutboundConnection.find_by!(
      provider_key: "dropbox",
      root_recording_id: @root.id
    )
    assert_equal "active", connection.status
    assert_equal "acct-demo", connection.external_account_id
    assert connection.access_token.present?
  end

  test "google drive disconnect after a live fake connect returns the row to connect" do
    follow_dummy_connect!(provider: "google_drive")
    connection = RecordingStudioOauth::OutboundConnection.find_by!(
      provider_key: "google_drive",
      root_recording_id: @root.id
    )

    delete "/recording_studio_oauth/outbound/connections/#{connection.id}", params: {
      owner: "root",
      root_recording_id: @root.id,
      return_to: recording_studio_plugins.root_path
    }

    assert_response :redirect
    follow_redirect!

    assert_equal recording_studio_plugins.root_path, request.path
    assert_equal "revoked", connection.reload.status
    assert_nil connection.access_token
    assert_select "form[action='/recording_studio_oauth/outbound/google_drive/connect']"
    assert_select "li[role='listitem']", text: /Google Drive/ do
      assert_select "button", text: "Connect"
      refute_select "*", text: "Connected"
    end
  end

  test "fake google authorize rejects a redirect that is not the outbound callback" do
    get "/fake_oauth/authorize", params: {
      client_id: FakeOauth::CLIENT_ID,
      redirect_uri: "https://evil.test/steal",
      state: "nope"
    }

    assert_response :bad_request
    assert_equal 0, RecordingStudioOauth::OutboundConnection.where(root_recording_id: @root.id).count
  end

  test "fake dropbox authorize rejects a redirect that is not the outbound callback" do
    get "/fake_oauth/authorize", params: {
      client_id: FakeDropboxOauth::CLIENT_ID,
      redirect_uri: "https://evil.test/steal",
      state: "nope"
    }

    assert_response :bad_request
    assert_equal 0, RecordingStudioOauth::OutboundConnection.where(root_recording_id: @root.id).count
  end

  test "admin sees a connect action that posts to oauth when authorize url is https" do
    RecordingStudioOauth.register_outbound_provider(
      key: :https_drive,
      kind: :root,
      authorize_url: "https://accounts.google.com/o/oauth2/auth",
      token_url: "https://oauth2.googleapis.com/token",
      revoke_url: "https://oauth2.googleapis.com/revoke",
      scopes: [ "files.read" ],
      client_id: "dummy-https-drive",
      client_secret: "dummy-https-drive-secret",
      pkce: true,
      refresh: true
    )
    RecordingStudioPlugins.configuration.enabled_plugins = %i[google_drive dropbox https_drive]

    with_csrf_protection do
      get recording_studio_plugins.root_path

      assert_response :success
      assert_select "form[method='post'][action='/recording_studio_oauth/outbound/https_drive/connect']"
      assert_select "form[action='/recording_studio_oauth/outbound/https_drive/connect'] input[name='authenticity_token']"
      assert_select "input[name='owner'][value='root']"
      assert_select "input[name='root_recording_id'][value=?]", @root.id.to_s
      assert_select "input[name='return_to'][value=?]", recording_studio_plugins.root_path
      refute_includes response.body, 'data-method="post"'
      assert_select "form[action='/recording_studio_oauth/outbound/https_drive/connect'] button[data-fp-style='secondary']", text: "Connect"
    end
  ensure
    restore_plugins!
  end

  test "admin sees a disconnect form for a live workspace connection" do
    connection = RecordingStudioOauth::OutboundConnection.create!(
      provider_key: "google_drive",
      root_recording_id: @root.id,
      connected_by: @user,
      access_token: "dummy-access-token",
      refresh_token: "dummy-refresh-token",
      status: "active",
      granted_scopes: [ "files.read" ]
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
      assert_select "form[action=?] button[data-fp-style='secondary']", action, text: "Connected"
      refute_select "form[action=?] button", action, text: "Disconnect"
    end
  end

  test "invalid action url is omitted and the row still renders" do
    register_plugin(:unsafe, provider: unsafe_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Unsafe"
    refute_includes response.body, "javascript:alert"
  end

  test "a raising status leaves the other rows rendered and each method runs once" do
    calls = Hash.new(0)
    register_plugin(:counted, provider: counting_provider(calls))
    register_plugin(:broken, name: "Broken plugin", provider: raising_provider)

    get recording_studio_plugins.root_path

    assert_response :success
    assert_includes response.body, "Broken plugin"
    assert_includes response.body, "ChatGPT"
    assert_equal 1, calls[:available?]
    assert_equal 1, calls[:status]
  end

  private

  def assert_directory_apostrophes
    assert_includes response.body, "See what you can connect, and what's already set up."
    refute_includes response.body, "&#39;"
    refute_includes response.body, "&amp;#39;"
  end

  def directory_rows
    css_select("li[role='listitem']").map { |node| node.text.gsub(/\s+/, " ").strip }
  end

  def count_directory_queries
    count = 0
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s
      next if payload[:name] == "SCHEMA"
      next unless sql.match?(/PluginAppearance|plugin_appearances|Attachable::Attachment|attachable_attachments/i)

      count += 1
    end
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get recording_studio_plugins.root_path
      end
    end
    count
  end

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
    load Rails.root.join("config/initializers/recording_studio_google_drive.rb")
    load Rails.root.join("config/initializers/recording_studio_dropbox.rb")
    load Rails.root.join("config/initializers/recording_studio_plugins.rb")
  end

  def follow_dummy_connect!(provider:)
    post "/recording_studio_oauth/outbound/#{provider}/connect", params: {
      owner: "root",
      root_recording_id: @root.id,
      return_to: recording_studio_plugins.root_path
    }

    assert_response :redirect
    authorize = URI.parse(response.redirect_url)
    assert_equal "/fake_oauth/authorize", authorize.path
    query = URI.decode_www_form(authorize.query.to_s).to_h
    expected_client = provider == "dropbox" ? FakeDropboxOauth::CLIENT_ID : FakeOauth::CLIENT_ID
    assert_equal expected_client, query["client_id"]
    assert query["state"].present?
    assert query["code_challenge"].present?
    assert_equal "S256", query["code_challenge_method"]
    refute_equal recording_studio_plugins.root_path, authorize.path

    follow_redirect!

    assert_response :redirect
    callback = URI.parse(response.redirect_url)
    assert_equal "/recording_studio_oauth/outbound/callback", callback.path
    callback_query = URI.decode_www_form(callback.query.to_s).to_h
    assert_equal query["state"], callback_query["state"]
    assert callback_query["code"].present?

    follow_redirect!

    assert_response :redirect
    follow_redirect!

    assert_response :success
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

  def connected_provider
    Class.new do
      def self.status(_context)
        RecordingStudioPlugins::Status.new(state: :connected)
      end
    end
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

  def switch_to_root!(root_recording)
    patch recording_studio_root_switchable.root_switch_path(scope: "all_workspaces"), params: {
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: recording_studio_plugins.root_path
      }
    }
    follow_redirect! if response.redirect?
  end

  def counting_provider(calls)
    Class.new do
      define_singleton_method(:available?) { |_context| calls[:available?] += 1; true }
      define_singleton_method(:status) do |_context|
        calls[:status] += 1
        RecordingStudioPlugins::Status.new(state: :connected)
      end
    end
  end
end
