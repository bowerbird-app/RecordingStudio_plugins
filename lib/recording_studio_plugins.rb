# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_oauth"
require "flat_pack"
require "recording_studio_plugins/version"
require "recording_studio_plugins/actor_label"
require "recording_studio_plugins/actor_label_config"
require "recording_studio_plugins/layout_config"
require "recording_studio_plugins/config_sources"
require "recording_studio_plugins/configuration"
require "recording_studio_plugins/definition"
require "recording_studio_plugins/registry"
require "recording_studio_plugins/status"
require "recording_studio_plugins/context"
require "recording_studio_plugins/safe_url"
require "recording_studio_plugins/listing"
require "recording_studio_plugins/known_providers"
require "recording_studio_plugins/oauth_paths"
require "recording_studio_plugins/oauth_adapter"
require "recording_studio_plugins/mcp_client_status"
require "recording_studio_plugins/inbound_people"
require "recording_studio_plugins/oauth_directory"
require "recording_studio_plugins/engine"

module RecordingStudioPlugins
  class Error < StandardError; end
  class RegistryConflict < Error; end
  class UnknownCategory < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def registry
      @registry ||= Registry.new
    end

    def register(key, **attributes)
      registry.register(Definition.build(key: key, **attributes))
    end

    def register_mcp_client(key, setup_url: nil, owner: "host")
      register(key, **mcp_client_attributes(key, setup_url: setup_url, owner: owner))
    end

    def mcp_client_attributes(key, setup_url:, owner:)
      meta = KnownProviders.fetch(key)
      raise ArgumentError, "#{key} is not a known MCP client plugin" if meta.nil?

      meta.slice(:name, :description, :category, :position).merge(
        icon: meta[:icon].to_s,
        provider: McpClientStatus.new(key),
        owner: owner,
        kind: :user,
        setup_url: setup_url
      )
    end

    def find(key)
      definition = registry.find(key) || OauthDirectory.find(key)
      definition && apply_overrides(definition)
    end

    def all
      (registry.all + OauthDirectory.definitions)
        .map { |definition| apply_overrides(definition) }
        .sort_by { |definition| [definition.position, definition.name] }
    end

    def available(context:)
      listings_for(context: context).map(&:definition)
    end

    def listings_for(context:)
      all.filter_map do |definition|
        next if configuration.hidden?(definition.key)
        next unless OauthDirectory.visible?(definition, context)

        listing = Listing.new(definition, context)
        listing if listing.listed?
      end
    end

    def clear!
      registry.clear!
    end

    def log_provider_failure(key, method_name, error)
      message = "RecordingStudioPlugins #{key} #{method_name} failed: #{error.class}: #{error.message}"
      logger = Rails.logger if defined?(Rails) && Rails.respond_to?(:logger)
      logger ? logger.error(message) : warn(message)
    end

    def apply_overrides(definition)
      values = configuration.override_for(definition.key)
      return definition if values.empty?

      if values[:category] && !configuration.category?(values[:category])
        raise UnknownCategory, "#{values[:category]} is not a plugin category"
      end

      definition.override(values)
    end
  end
end
