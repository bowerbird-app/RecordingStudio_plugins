# frozen_string_literal: true

require "test_helper"

class InboundDirectoryTest < Minitest::Test
  def setup
    RecordingStudioPlugins.clear!
    @configuration = RecordingStudioPlugins.configuration
    @original_enabled = @configuration.enabled_plugins
    @original_label = @configuration.instance_variable_get(:@actor_label)
  end

  def teardown
    RecordingStudioPlugins.clear!
    @configuration.enabled_plugins = @original_enabled
    @configuration.actor_label = @original_label
  end

  def test_host_registration_lists_inbound_plugins_for_members
    register_clients

    with_inbound_status(connected: false, connected_count: nil) do
      keys = RecordingStudioPlugins.listings_for(context: member_context).map(&:key)

      assert_equal %i[chatgpt grok_bot], keys
    end
  end

  def test_admins_see_inbound_and_workspace_plugins
    @configuration.enabled_plugins = %i[google_drive]
    register_clients

    with_oauth_and_inbound do
      keys = RecordingStudioPlugins.listings_for(context: admin_context).map(&:key)

      assert_equal %i[chatgpt grok_bot google_drive], keys
    end
  end

  def test_members_do_not_see_workspace_plugins
    @configuration.enabled_plugins = %i[google_drive]
    register_clients

    with_oauth_and_inbound do
      keys = RecordingStudioPlugins.listings_for(context: member_context).map(&:key)

      assert_equal %i[chatgpt grok_bot], keys
      refute RecordingStudioPlugins::OauthDirectory.visible?(
        RecordingStudioPlugins.find(:google_drive),
        member_context
      )
    end
  end

  def test_member_status_has_no_count_and_no_connect_action
    register_clients

    with_inbound_status(connected: true, connected_count: nil) do
      listing = RecordingStudioPlugins.listings_for(context: member_context).first

      assert_equal "Connected", listing.directory_status_text
      assert_nil listing.people_connected_text
      refute listing.action?(can_edit: true)
    end
  end

  def test_admin_status_includes_count
    register_clients

    with_inbound_status(connected: true, connected_count: 3) do
      listing = RecordingStudioPlugins.listings_for(context: admin_context).first

      assert_equal "Connected", listing.directory_status_text
      assert_equal "3 people connected", listing.people_connected_text
    end
  end

  def test_not_connected_status_text
    register_clients

    with_inbound_status(connected: false, connected_count: 0) do
      listing = RecordingStudioPlugins.listings_for(context: admin_context).first

      assert_nil listing.directory_status_text
      assert_nil listing.people_connected_text
    end
  end

  def test_setup_url_is_https_only
    error = assert_raises(ArgumentError) do
      RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "http://example.com/chatgpt")
    end

    assert_includes error.message, "https"

    javascript = assert_raises(ArgumentError) do
      RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "javascript:alert(1)")
    end

    assert_includes javascript.message, "https"

    RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "https://example.com/chatgpt")
    listing = listing_for(:chatgpt, connected: false, connected_count: nil)

    assert_equal "https://example.com/chatgpt", listing.setup_href
  end

  def test_missing_setup_url_has_no_connect_href
    RecordingStudioPlugins.register_mcp_client(:chatgpt, owner: "test")
    listing = listing_for(:chatgpt, connected: false, connected_count: nil)

    assert_nil listing.setup_href
  end

  def test_status_does_not_carry_across_roots
    register_clients
    root_a = Struct.new(:id).new("a")
    root_b = Struct.new(:id).new("b")
    lookup = lambda do |plugin_key:, root:, actor:|
      raise "unexpected plugin" unless plugin_key == :chatgpt
      raise "unexpected actor" unless actor == :admin

      connected = root.equal?(root_a)
      { connected: connected, connected_count: connected ? 1 : 0 }
    end

    RecordingStudioPlugins::McpClientStatus.stub(:connection_status, lookup) do
      listing_a = RecordingStudioPlugins::Listing.new(
        RecordingStudioPlugins.find(:chatgpt),
        RecordingStudioPlugins::Context.new(actor: :admin, root_recording: root_a)
      )
      listing_b = RecordingStudioPlugins::Listing.new(
        RecordingStudioPlugins.find(:chatgpt),
        RecordingStudioPlugins::Context.new(actor: :admin, root_recording: root_b)
      )

      assert_equal "Connected", listing_a.directory_status_text
      assert_nil listing_b.directory_status_text
    end
  end

  def test_inbound_people_uses_default_actor_label
    register_clients
    actor = Struct.new(:id, :name, :email).new("1", nil, "kit@example.com")
    rows = [{
      actor_type: "User",
      actor_id: "1",
      role: "edit",
      connected_at: Time.utc(2026, 1, 1),
      last_used_at: nil,
      app_name: "ChatGPT"
    }]

    with_actor_class(actor) do
      people = RecordingStudioPlugins::InboundPeople.new(rows).labeled

      assert_equal "kit@example.com", people.first[:name]
    end
  end

  def test_inbound_people_uses_overridden_actor_label
    register_clients
    @configuration.actor_label = ->(_actor) { "Nickname" }
    actor = Struct.new(:id, :name, :email).new("1", "Kit", "kit@example.com")
    rows = [{
      actor_type: "User",
      actor_id: "1",
      role: "admin",
      connected_at: Time.utc(2026, 1, 1),
      last_used_at: Time.utc(2026, 1, 2),
      app_name: "ChatGPT"
    }]

    with_actor_class(actor) do
      people = RecordingStudioPlugins::InboundPeople.new(rows).labeled

      assert_equal "Nickname", people.first[:name]
    end
  end

  def test_inbound_people_ignores_non_model_actor_type
    rows = [{
      actor_type: "String",
      actor_id: "1",
      role: "edit",
      connected_at: Time.utc(2026, 1, 1),
      last_used_at: nil,
      app_name: "ChatGPT"
    }]

    people = RecordingStudioPlugins::InboundPeople.new(rows).labeled

    assert_nil RecordingStudioPlugins::InboundPeople.actor_class_for("String")
    assert_equal "User", people.first[:name]
  end

  def test_directory_listings_do_not_load_inbound_people
    register_clients
    called = 0

    labeled = lambda do |**_|
      called += 1
      []
    end
    RecordingStudioPlugins::InboundPeople.stub(:labeled, labeled) do
      with_inbound_status(connected: true, connected_count: 2) do
        listings = RecordingStudioPlugins.listings_for(context: admin_context)
        listings.each do |listing|
          listing.directory_status_text
          listing.people_connected_text
        end
      end
    end

    assert_equal 0, called
  end

  def test_unknown_mcp_client_key_raises
    error = assert_raises(ArgumentError) do
      RecordingStudioPlugins.register_mcp_client(:not_a_client)
    end

    assert_includes error.message, "not_a_client"
  end

  private

  def register_clients
    RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "https://example.com/chatgpt")
    RecordingStudioPlugins.register_mcp_client(:grok_bot, setup_url: "https://example.com/grok")
  end

  def listing_for(key, connected:, connected_count:)
    with_inbound_status(connected: connected, connected_count: connected_count) do
      RecordingStudioPlugins::Listing.new(RecordingStudioPlugins.find(key), admin_context)
    end
  end

  def with_inbound_status(connected:, connected_count:, &)
    payload = { connected: connected, connected_count: connected_count }
    RecordingStudioPlugins::McpClientStatus.stub(:connection_status, ->(**_) { payload }, &)
  end

  def with_oauth_and_inbound(&block)
    status = ->(**_) { { workspace: :missing, personal: :missing } }
    inbound = ->(**_) { { connected: false, connected_count: 0 } }
    RecordingStudioPlugins::OauthDirectory.stub(:admin?, method(:admin_actor?)) do
      RecordingStudioOauth.stub(:outbound_providers, [{ key: :google_drive, kind: :root }]) do
        RecordingStudioOauth.stub(:combined_connection_status, status) do
          RecordingStudioPlugins::McpClientStatus.stub(:connection_status, inbound, &block)
        end
      end
    end
  end

  def with_actor_class(actor, &)
    relation = Object.new
    relation.define_singleton_method(:to_a) { [actor] }
    user_class = Object.new
    user_class.define_singleton_method(:where) do |id:|
      raise "unexpected ids #{id.inspect}" unless id == ["1"]

      relation
    end
    RecordingStudioPlugins::InboundPeople.stub(:actor_class_for, ->(_type) { user_class }, &)
  end

  def admin_actor?(plugin_context)
    plugin_context.actor == :admin
  end

  def admin_context
    RecordingStudioPlugins::Context.new(actor: :admin, root_recording: root_recording)
  end

  def member_context
    RecordingStudioPlugins::Context.new(actor: :member, root_recording: root_recording)
  end

  def root_recording
    @root_recording ||= Struct.new(:id).new("root-1")
  end
end
