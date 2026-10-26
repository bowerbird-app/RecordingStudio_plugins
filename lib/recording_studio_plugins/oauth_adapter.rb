# frozen_string_literal: true

module RecordingStudioPlugins
  class OauthAdapter
    def initialize(key)
      @key = key.to_sym
    end

    def status(plugin_context)
      root = plugin_context.root_recording
      actor = plugin_context.actor
      return if root.nil? || actor.nil?

      combined = RecordingStudioOauth.combined_connection_status(
        provider: @key,
        root: root,
        actor: actor
      )
      map_workspace_status(combined.fetch(:workspace), root, actor)
    end

    def about(_plugin_context)
      KnownProviders.fetch(@key)&.fetch(:about, nil)
    end

    private

    def map_workspace_status(workspace, root, actor)
      case workspace
      when :active then active_status(root, actor)
      when :needs_reconnect then reconnect_status
      when :missing then missing_status
      end
    end

    def active_status(root, actor)
      Status.new(
        state: :connected,
        action_label: copy("status.disconnect"),
        action_url: disconnect_url(root, actor)
      )
    end

    def reconnect_status
      Status.new(
        state: :attention,
        message: copy("status.reconnect"),
        action_label: copy("status.reconnect_action"),
        action_url: connect_url
      )
    end

    def missing_status
      Status.new(action_label: copy("status.connect"), action_url: connect_url)
    end

    def connect_url
      OauthPaths.connect(provider: @key)
    end

    def disconnect_url(root, actor)
      connection_id = RecordingStudioOauth.connection_id_for(
        provider: @key,
        root: root,
        actor: actor
      )
      return if connection_id.blank?

      OauthPaths.disconnect(connection_id)
    end

    def copy(key)
      RecordingStudio.t("recording_studio.plugins.#{key}")
    end
  end
end
