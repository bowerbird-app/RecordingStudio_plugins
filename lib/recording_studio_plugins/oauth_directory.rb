# frozen_string_literal: true

module RecordingStudioPlugins
  module OauthDirectory
    OWNER = "recording_studio_oauth"

    module_function

    def definitions
      enabled = RecordingStudioPlugins.configuration.enabled_plugins
      return [] if enabled.empty? || !defined?(RecordingStudioOauth)

      registered_keys = RecordingStudioPlugins.registry.all.map(&:key)
      RecordingStudioOauth.outbound_providers.filter_map do |entry|
        definition_for(entry, enabled: enabled, registered_keys: registered_keys)
      end
    end

    def find(key)
      symbol = key&.to_sym
      definitions.find { |definition| definition.key == symbol }
    end

    def admin?(plugin_context)
      root = plugin_context.root_recording
      actor = plugin_context.actor
      return false if root.nil? || actor.nil?

      RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :admin)
    end

    def visible?(definition, plugin_context)
      return true unless definition.kind == :root

      admin?(plugin_context)
    end

    def definition_for(entry, enabled:, registered_keys:)
      key = normalize_key(entry[:key] || entry["key"])
      kind = (entry[:kind] || entry["kind"])&.to_sym
      return unless listable_root?(key, kind, enabled, registered_keys)

      build_definition(key, kind)
    end

    def listable_root?(key, kind, enabled, registered_keys)
      key && kind == :root && enabled.include?(key) && registered_keys.exclude?(key)
    end

    def normalize_key(value)
      text = value.to_s.strip
      return if text.empty?

      text.to_sym
    end

    def build_definition(key, kind)
      meta = KnownProviders.fetch(key) || {}
      Definition.build(**definition_attributes(key, kind, meta))
    end

    def definition_attributes(key, kind, meta)
      display_for(key, meta).merge(
        key: key, provider: OauthAdapter.new(key), owner: OWNER, kind: kind
      )
    end

    def display_for(key, meta)
      {
        name: meta[:name] || key.to_s.humanize,
        description: meta[:description].to_s,
        category: meta[:category] || :other,
        icon: meta[:icon].to_s,
        position: meta[:position] || 100
      }
    end
    private_class_method :definition_for, :listable_root?, :normalize_key, :build_definition,
                         :definition_attributes, :display_for
  end
end
