# frozen_string_literal: true

require "test_helper"
require "recording_studio_plugins/dashboard/installable_plugins"

class InstallablePluginsWidgetTest < Minitest::Test
  FakePreparation = Struct.new(:state, :data, :message, keyword_init: true)

  def setup
    RecordingStudioPlugins.clear!
    stub_dashboard_preparation
  end

  def teardown
    RecordingStudioPlugins.clear!
    restore_dashboard_preparation
  end

  def test_prepare_returns_empty_when_every_visible_plugin_is_connected
    register_plugin(:drive, connected: true)

    result = with_directory_visibility do
      RecordingStudioPlugins::Dashboard::InstallablePlugins.prepare(admin_context, {})
    end

    assert_equal :empty, result.state
    assert_equal "Nothing to connect right now.", result.message
  end

  def test_prepare_returns_empty_when_nothing_is_visible
    result = with_directory_visibility do
      RecordingStudioPlugins::Dashboard::InstallablePlugins.prepare(member_context, {})
    end

    assert_equal :empty, result.state
  end

  def test_prepare_includes_unconnected_plugins_only
    register_plugin(:drive, connected: false, kind: :root)
    register_plugin(:dropbox, connected: true, kind: :root)
    register_plugin(:chatgpt, connected: false, kind: :user)

    admin_cards = with_directory_visibility do
      RecordingStudioPlugins::Dashboard::InstallablePlugins.prepare(admin_context, {}).data
    end
    member_cards = with_directory_visibility do
      RecordingStudioPlugins::Dashboard::InstallablePlugins.prepare(member_context, {}).data
    end

    assert_equal %i[chatgpt drive], admin_cards.map(&:key).sort
    assert_equal %i[chatgpt], member_cards.map(&:key)
    assert_equal "sample chatgpt", admin_cards.find { |card| card.key == :chatgpt }.name
    assert_equal "/recording_studio_plugins/", admin_cards.find { |card| card.key == :drive }.href
    refute admin_cards.find { |card| card.key == :drive }.external
  end

  def test_inbound_cards_use_the_directory_connect_href
    RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "https://chatgpt.com", owner: "test")
    cards = with_directory_visibility do
      RecordingStudioPlugins::Dashboard::InstallablePlugins.prepare(member_context, {}).data
    end
    card = cards.find { |item| item.key == :chatgpt }

    assert_equal "https://chatgpt.com", card.href
    assert card.external
  end

  def test_visible_requires_an_actor_and_root
    refute RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(WidgetContext.new)
    refute RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(WidgetContext.new(actor: :admin))
    refute RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(WidgetContext.new(root_recording: :root))
  end

  def test_visible_follows_directory_view_access
    RecordingStudioAccessible.stub(:authorized?, lambda { |actor:, recording:, role:|
      actor == :admin && recording == :root && role == :view
    }) do
      assert RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(admin_context)
      refute RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(
        WidgetContext.new(actor: :stranger, root_recording: :root)
      )
    end
  end

  def test_visible_rescues_permission_errors
    RecordingStudioAccessible.stub(:authorized?, ->(**) { raise "boom" }) do
      refute RecordingStudioPlugins::Dashboard::InstallablePlugins.visible?(admin_context)
    end
  end

  def test_listing_exposes_connected_from_status
    listing = listing_for(connected: true)

    assert listing.connected?
    refute listing_for(key: :open, connected: false).connected?
  end

  private

  def stub_dashboard_preparation
    return if defined?(::RecordingStudioDashboard::Preparation) &&
              ::RecordingStudioDashboard::Preparation.respond_to?(:empty)

    @dashboard_stubbed = !defined?(::RecordingStudioDashboard)
    dashboard = defined?(::RecordingStudioDashboard) ? ::RecordingStudioDashboard : Module.new
    Object.const_set(:RecordingStudioDashboard, dashboard) unless defined?(::RecordingStudioDashboard)
    preparation = Module.new
    preparation.define_singleton_method(:empty) do |message: nil|
      FakePreparation.new(state: :empty, data: nil, message: message)
    end
    preparation.define_singleton_method(:content) do |data|
      FakePreparation.new(state: :content, data: data, message: nil)
    end
    dashboard.const_set(:Preparation, preparation) unless dashboard.const_defined?(:Preparation, false)
  end

  def restore_dashboard_preparation
    return unless @dashboard_stubbed

    Object.send(:remove_const, :RecordingStudioDashboard) if defined?(::RecordingStudioDashboard)
  end

  def register_plugin(key, connected:, kind: :user)
    RecordingStudioPlugins.register(
      key,
      name: "sample #{key}",
      description: "desc",
      category: :storage,
      icon: "puzzle-piece",
      provider: status_provider(connected),
      position: 1,
      owner: "test",
      kind: kind
    )
  end

  def listing_for(connected:, key: :sample)
    register_plugin(key, connected: connected)
    RecordingStudioPlugins::Listing.new(RecordingStudioPlugins.find(key), admin_plugin_context)
  end

  def status_provider(connected)
    status = RecordingStudioPlugins::Status.new(state: (connected ? :connected : nil))
    Class.new do
      define_singleton_method(:status) { |_context| status }
    end
  end

  WidgetContext = Struct.new(:actor, :root_recording, :request, keyword_init: true)

  def admin_context
    WidgetContext.new(actor: :admin, root_recording: :root)
  end

  def member_context
    WidgetContext.new(actor: :member, root_recording: :root)
  end

  def admin_plugin_context
    RecordingStudioPlugins::Context.new(actor: :admin, root_recording: :root)
  end

  def with_directory_visibility(&)
    RecordingStudioPlugins::OauthDirectory.stub(:admin?, ->(context) { context.actor == :admin }, &)
  end
end
