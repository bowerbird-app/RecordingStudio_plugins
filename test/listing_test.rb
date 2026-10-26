# frozen_string_literal: true

require "test_helper"

class ListingTest < Minitest::Test
  def setup
    RecordingStudioPlugins.clear!
    @calls = Hash.new(0)
  end

  def teardown
    RecordingStudioPlugins.clear!
  end

  def test_metadata_only_plugin_is_listed_with_a_setup_action_and_no_badge
    listing = listing_for(provider: Object.new)

    assert listing.listed?
    assert_nil listing.badge_style
    assert listing.action?(can_edit: true)
    assert_equal "Set up", listing.action_label
    assert_nil listing.action_href
    refute listing.action?(can_edit: false)
  end

  def test_connected_status_shows_a_badge_and_no_action
    provider = status_provider(RecordingStudioPlugins::Status.new(state: :connected, action_label: "Connect"))
    listing = listing_for(provider: provider)

    assert_equal :success, listing.badge_style
    assert_equal "Connected", listing.badge_text
    refute listing.action?(can_edit: true)
  end

  def test_connected_status_with_a_url_keeps_the_action
    provider = status_provider(
      RecordingStudioPlugins::Status.new(
        state: :connected,
        action_label: "Disconnect",
        action_url: "/recording_studio_oauth/outbound/connections/1"
      )
    )
    listing = listing_for(provider: provider)

    assert listing.action?(can_edit: true)
    assert_equal "/recording_studio_oauth/outbound/connections/1", listing.action_href
    refute listing.action?(can_edit: false)
  end

  def test_attention_status_shows_a_badge_message_and_action
    provider = status_provider(
      RecordingStudioPlugins::Status.new(
        state: :attention,
        message: "Check the connection",
        action_label: "Check connection",
        action_url: "/plugins/check"
      )
    )
    listing = listing_for(provider: provider)

    assert_equal :warning, listing.badge_style
    assert_equal "Attention", listing.badge_text
    assert_equal "Check the connection", listing.message
    assert listing.action?(can_edit: true)
    assert_equal "/plugins/check", listing.action_href
    refute listing.action_external?
  end

  def test_status_raise_hides_badge_and_action_for_that_plugin_only
    broken = Class.new do
      def self.status(_context)
        raise "status failed"
      end
    end
    broken_listing = listing_for(key: :broken, provider: broken)
    connected = RecordingStudioPlugins::Status.new(state: :connected)
    healthy = listing_for(key: :healthy, provider: status_provider(connected))

    assert broken_listing.listed?
    assert_nil broken_listing.badge_style
    refute broken_listing.action?(can_edit: true)
    assert_equal :success, healthy.badge_style
  end

  def test_available_false_hides_the_plugin_and_a_raise_keeps_it_listed
    hidden = Class.new do
      def self.available?(_context)
        false
      end
    end
    raised = Class.new do
      def self.available?(_context)
        raise "unavailable"
      end
    end

    refute listing_for(key: :hidden, provider: hidden).listed?
    assert listing_for(key: :raised, provider: raised).listed?
    assert_equal [:raised], RecordingStudioPlugins.available(context: context_for).map(&:key)
  end

  def test_each_provider_method_is_called_once
    provider = counting_provider
    listing = listing_for(provider: provider)

    2.times do
      listing.listed?
      listing.badge_style
      listing.action?(can_edit: true)
      listing.about
      listing.setup_instructions
      listing.usage_instructions
      listing.documentation_url
    end

    assert_equal(
      { available?: 1, status: 1, about: 1, setup_instructions: 1, usage_instructions: 1, documentation_url: 1 },
      @calls
    )
  end

  def test_invalid_action_url_omits_the_action
    provider = status_provider(
      RecordingStudioPlugins::Status.new(action_label: "Connect", action_url: "javascript:alert(1)")
    )
    listing = listing_for(provider: provider)

    refute listing.action?(can_edit: true)
    assert_nil listing.action_href
  end

  def test_provider_text_is_returned_as_a_plain_string
    provider = Class.new do
      def self.about(_context)
        "<script>alert(1)</script>"
      end
    end
    listing = listing_for(provider: provider)

    assert_equal "<script>alert(1)</script>", listing.about
    refute listing.about.html_safe?
  end

  private

  def listing_for(provider:, key: :sample)
    RecordingStudioPlugins.register(
      key,
      name: key.to_s,
      description: "A plugin",
      category: :storage,
      icon: "cloud",
      provider: provider,
      position: 1,
      owner: "test"
    )
    RecordingStudioPlugins::Listing.new(RecordingStudioPlugins.find(key), context_for)
  end

  def context_for
    @context_for ||= RecordingStudioPlugins::Context.new(actor: nil, root_recording: nil)
  end

  def status_provider(status)
    Class.new do
      define_singleton_method(:status) { |_context| status }
    end
  end

  def counting_provider
    calls = @calls
    Class.new do
      define_singleton_method(:available?) do |_context|
        calls[:available?] += 1
        true
      end
      define_singleton_method(:status) do |_context|
        calls[:status] += 1
        RecordingStudioPlugins::Status.new(state: :connected)
      end
      define_singleton_method(:about) do |_context|
        calls[:about] += 1
        "About"
      end
      define_singleton_method(:setup_instructions) do |_context|
        calls[:setup_instructions] += 1
        "Connect"
      end
      define_singleton_method(:usage_instructions) do |_context|
        calls[:usage_instructions] += 1
        "Use"
      end
      define_singleton_method(:documentation_url) do |_context|
        calls[:documentation_url] += 1
        "https://example.com/docs"
      end
    end
  end
end
