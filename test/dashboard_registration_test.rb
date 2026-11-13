# frozen_string_literal: true

require "test_helper"

class DashboardRegistrationTest < Minitest::Test
  def test_registration_noops_without_the_dashboard_gem
    hide_dashboard_constant

    refute defined?(::RecordingStudioDashboard)
    assert_nil RecordingStudioPlugins::Dashboard.register!
  ensure
    restore_dashboard_constant
  end

  def test_registration_declares_the_installable_plugins_widget
    hide_dashboard_constant
    calls = []
    dashboard = Module.new
    dashboard.define_singleton_method(:register_widget) do |id, **registration|
      calls << [id, registration]
    end
    Object.const_set(:RecordingStudioDashboard, dashboard)

    RecordingStudioPlugins::Dashboard.register!

    assert_equal 1, calls.size
    id, registration = calls.first
    assert_equal :installable_plugins, id
    assert_equal RecordingStudioPlugins::Dashboard::InstallablePlugins::Component, registration[:component]
    assert_equal 12, registration[:default_span]
    assert_equal :message, registration[:empty]
    assert_equal "Nothing to connect right now.", registration[:empty_message]
    assert_respond_to registration[:permission], :call
    assert_respond_to registration[:component], :prepare
  ensure
    restore_dashboard_constant
  end

  def test_registration_is_idempotent
    hide_dashboard_constant
    calls = []
    widgets = {}
    dashboard = Module.new
    dashboard.define_singleton_method(:register_widget) do |id, **registration|
      raise ArgumentError, "widget #{id} is already registered" if widgets.key?(id)

      widgets[id] = true
      calls << [id, registration]
    end
    registry = Object.new
    dashboard.define_singleton_method(:registry) { registry }
    registry.define_singleton_method(:widget) do |id|
      raise KeyError unless widgets.key?(id)

      true
    end
    Object.const_set(:RecordingStudioDashboard, dashboard)

    RecordingStudioPlugins::Dashboard.register!
    RecordingStudioPlugins::Dashboard.register!

    assert_equal 1, calls.size
  ensure
    restore_dashboard_constant
  end

  def test_gemspec_does_not_depend_on_recording_studio_dashboard
    gemspec = File.read(File.expand_path("../recording_studio_plugins.gemspec", __dir__))
    entry = File.read(File.expand_path("../lib/recording_studio_plugins.rb", __dir__))
    engine = File.read(File.expand_path("../lib/recording_studio_plugins/engine.rb", __dir__))

    refute_includes gemspec, "recording_studio_dashboard"
    refute_includes entry, 'require "recording_studio_dashboard"'
    assert_includes entry, 'require "recording_studio_plugins/dashboard"'
    assert_includes engine, 'initializer "recording_studio_plugins.dashboard", before: :load_config_initializers'
    refute_includes engine, "RecordingStudioDashboard.reset!"
  end

  def test_dummy_pins_dashboard_v0_4_1
    dummy_gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))
    root_gemfile = File.read(File.expand_path("../Gemfile", __dir__))

    pin = 'gem "recording_studio_dashboard", github: "bowerbird-app/RecordingStudio_dashboard", tag: "v0.4.1"'
    assert_includes dummy_gemfile, pin
    assert_includes root_gemfile, pin
  end

  private

  def hide_dashboard_constant
    @saved_dashboard = defined?(::RecordingStudioDashboard) ? ::RecordingStudioDashboard : :absent
    Object.send(:remove_const, :RecordingStudioDashboard) if defined?(::RecordingStudioDashboard)
  end

  def restore_dashboard_constant
    Object.send(:remove_const, :RecordingStudioDashboard) if defined?(::RecordingStudioDashboard)
    return if @saved_dashboard == :absent || @saved_dashboard.nil?

    Object.const_set(:RecordingStudioDashboard, @saved_dashboard)
  end
end
