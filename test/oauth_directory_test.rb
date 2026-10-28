# frozen_string_literal: true

require "test_helper"

class OauthDirectoryTest < Minitest::Test
  def setup
    RecordingStudioPlugins.clear!
    @configuration = RecordingStudioPlugins.configuration
    @original = {
      hidden_keys: @configuration.hidden_keys,
      overrides: @configuration.overrides,
      extra_categories: @configuration.extra_categories,
      enabled_plugins: @configuration.enabled_plugins
    }
  end

  def teardown
    RecordingStudioPlugins.clear!
    @configuration.hidden_keys = @original[:hidden_keys]
    @configuration.overrides = @original[:overrides]
    @configuration.extra_categories = @original[:extra_categories]
    @configuration.enabled_plugins = @original[:enabled_plugins]
  end

  def test_enabled_plugins_default_lists_nothing_from_oauth
    @configuration.enabled_plugins = []

    RecordingStudioOauth.stub(:outbound_providers, [{ key: :google_drive, kind: :root }]) do
      assert_empty RecordingStudioPlugins.listings_for(context: admin_context)
    end
  end

  def test_enabled_and_registered_root_plugin_is_listed_for_admins
    @configuration.enabled_plugins = %i[google_drive dropbox]

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :missing) do
      keys = RecordingStudioPlugins.listings_for(context: admin_context).map(&:key)

      assert_equal [:google_drive], keys
    end
  end

  def test_enabled_but_unregistered_provider_is_not_listed
    @configuration.enabled_plugins = %i[google_drive dropbox]

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :missing) do
      keys = RecordingStudioPlugins.listings_for(context: admin_context).map(&:key)

      refute_includes keys, :dropbox
    end
  end

  def test_non_admin_does_not_see_root_plugins
    @configuration.enabled_plugins = %i[google_drive]

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :active) do
      assert_empty RecordingStudioPlugins.listings_for(context: member_context)
      refute RecordingStudioPlugins::OauthDirectory.visible?(
        RecordingStudioPlugins.find(:google_drive),
        member_context
      )
    end
  end

  def test_missing_maps_to_connect_for_admins_only
    @configuration.enabled_plugins = %i[google_drive]

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :missing) do
      listing = RecordingStudioPlugins.listings_for(context: admin_context).first

      assert listing.action?(can_edit: true)
      assert_equal "Connect", listing.action_label
      assert_equal "/recording_studio_oauth/outbound/google_drive/connect", listing.action_href
      assert_equal "root-1", listing.action_root_recording_id
      assert_equal :post, listing.action_method
      refute listing.action?(can_edit: false)
    end
  end

  def test_missing_connects_even_when_authorize_url_is_not_https
    @configuration.enabled_plugins = %i[google_drive]

    %w[/fake_oauth/authorize http://example.com/oauth javascript:alert(1)].each do |authorize_url|
      with_oauth_providers(
        [{ key: :google_drive, kind: :root }],
        workspace: :missing,
        authorize_url: authorize_url
      ) do
        listing = RecordingStudioPlugins.listings_for(context: admin_context).first

        assert listing.action?(can_edit: true), authorize_url
        assert_equal "/recording_studio_oauth/outbound/google_drive/connect", listing.action_href
      end
    end
  end

  def test_connect_fails_loudly_if_outbound_provider_lookup_raises
    @configuration.enabled_plugins = %i[google_drive]
    status = ->(**_) { { workspace: :missing, personal: :missing } }
    boom = lambda do |*_args|
      raise "Oauth outbound provider lookup must not be required to show Connect"
    end

    RecordingStudioPlugins::OauthDirectory.stub(:admin?, method(:admin_actor?)) do
      RecordingStudioOauth.stub(:outbound_providers, [{ key: :google_drive, kind: :root }]) do
        RecordingStudioOauth::Outbound.stub(:provider, boom) do
          RecordingStudioOauth.stub(:combined_connection_status, status) do
            listing = RecordingStudioPlugins.listings_for(context: admin_context).first

            assert listing.action?(can_edit: true)
            assert_equal "Connect", listing.action_label
            assert_equal "/recording_studio_oauth/outbound/google_drive/connect", listing.action_href
          end
        end
      end
    end
  end

  def test_active_maps_to_connected_with_disconnect
    @configuration.enabled_plugins = %i[google_drive]

    with_oauth_providers(
      [{ key: :google_drive, kind: :root }],
      workspace: :active,
      connection_id: "conn-1"
    ) do
      listing = RecordingStudioPlugins.listings_for(context: admin_context).first

      assert_equal :success, listing.badge_style
      assert_equal "Connected", listing.badge_text
      assert listing.action?(can_edit: true)
      assert_equal "Disconnect", listing.action_label
      assert_equal "/recording_studio_oauth/outbound/connections/conn-1", listing.action_href
      assert_equal :delete, listing.action_method
      refute listing.action?(can_edit: false)
    end
  end

  def test_needs_reconnect_maps_to_attention
    @configuration.enabled_plugins = %i[dropbox]

    with_oauth_providers([{ key: :dropbox, kind: :root }], workspace: :needs_reconnect) do
      listing = RecordingStudioPlugins.listings_for(context: admin_context).first

      assert_equal :warning, listing.badge_style
      assert_equal "Attention", listing.badge_text
      assert_equal "This connection needs another look.", listing.message
      assert_equal "Reconnect", listing.action_label
      assert listing.action?(can_edit: true)
      assert_equal :post, listing.action_method
    end
  end

  def test_host_overrides_rename_an_oauth_plugin
    @configuration.enabled_plugins = %i[google_drive]
    @configuration.overrides = { google_drive: { name: "Drive" } }

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :missing) do
      assert_equal "Drive", RecordingStudioPlugins.find(:google_drive).name
    end
  end

  def test_enabled_user_kind_provider_is_not_listed
    @configuration.enabled_plugins = %i[google_drive personal_drive]

    with_oauth_providers(
      [
        { key: :google_drive, kind: :root },
        { key: :personal_drive, kind: :user }
      ],
      workspace: :missing
    ) do
      keys = RecordingStudioPlugins.listings_for(context: admin_context).map(&:key)

      assert_equal [:google_drive], keys
      assert_nil RecordingStudioPlugins.find(:personal_drive)
    end
  end

  def test_registered_plugins_keep_working_alongside_oauth
    @configuration.enabled_plugins = %i[google_drive]
    RecordingStudioPlugins.register(
      :wordpress,
      name: "WordPress",
      description: "Publish",
      category: :websites,
      icon: "globe-alt",
      provider: Object.new,
      position: 30,
      owner: "dummy"
    )

    with_oauth_providers([{ key: :google_drive, kind: :root }], workspace: :missing) do
      member_keys = RecordingStudioPlugins.listings_for(context: member_context).map(&:key)
      admin_keys = RecordingStudioPlugins.listings_for(context: admin_context).map(&:key)

      assert_equal [:wordpress], member_keys
      assert_equal %i[google_drive wordpress], admin_keys
    end
  end

  private

  def with_oauth_providers(
    providers,
    workspace:,
    connection_id: nil,
    authorize_url: "https://accounts.example.com/o/oauth2/auth",
    &block
  )
    status = ->(**_) { { workspace: workspace, personal: :missing } }
    lookup = lambda do |key|
      match = providers.find { |entry| (entry[:key] || entry["key"]).to_s == key.to_s }
      Struct.new(:authorize_url).new(authorize_url) if match
    end
    RecordingStudioPlugins::OauthDirectory.stub(:admin?, method(:admin_actor?)) do
      RecordingStudioOauth.stub(:outbound_providers, providers) do
        RecordingStudioOauth::Outbound.stub(:provider, lookup) do
          RecordingStudioOauth.stub(:combined_connection_status, status) do
            RecordingStudioOauth.stub(:connection_id_for, ->(**_) { connection_id }, &block)
          end
        end
      end
    end
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
