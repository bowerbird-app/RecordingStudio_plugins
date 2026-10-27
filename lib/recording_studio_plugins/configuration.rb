# frozen_string_literal: true

module RecordingStudioPlugins
  class Configuration
    DEFAULT_CATEGORIES = %i[ai_agents storage social websites automation other].freeze

    attr_reader :hooks
    attr_accessor :mount_path, :admin_root_name, :admin_recording_resolver

    def initialize
      @mount_path = "/recording_studio_plugins"
      @hidden_keys = []
      @overrides = {}
      @extra_categories = []
      @enabled_plugins = []
      @admin_root_types = ["AdminRoot"]
      @admin_root_name = "Admin"
      @admin_recording_resolver = default_admin_recording_resolver
      @hooks = RecordingStudio::Hooks.new
    end

    def admin_root_types
      @admin_root_types.dup
    end

    def admin_root_types=(types)
      @admin_root_types = Array(types).map(&:to_s)
    end

    def hidden_keys
      @hidden_keys.dup
    end

    def hidden_keys=(keys)
      @hidden_keys = Array(keys).map(&:to_s)
    end

    def hidden?(key)
      @hidden_keys.include?(key.to_s)
    end

    def overrides
      @overrides.transform_values(&:dup)
    end

    def overrides=(values)
      @overrides = {}
      return if values.nil?

      values.to_h.each do |key, override|
        @overrides[key.to_s] = Override.normalize(override)
      end
    end

    def override_for(key)
      (@overrides[key.to_s] || {}).dup
    end

    def extra_categories
      @extra_categories.dup
    end

    def extra_categories=(categories)
      @extra_categories = Array(categories).map(&:to_sym)
    end

    def enabled_plugins
      @enabled_plugins.dup
    end

    def enabled_plugins=(keys)
      @enabled_plugins = Array(keys).map(&:to_sym)
    end

    def categories
      (DEFAULT_CATEGORIES + @extra_categories).uniq
    end

    def category?(category)
      return false if category.nil? || category.to_s.strip.empty?

      categories.include?(category.to_sym)
    end

    def to_h
      config_snapshot.merge(hooks_registered: hook_counts)
    end

    private

    def config_snapshot
      {
        mount_path:, hidden_keys:, overrides:, extra_categories:,
        enabled_plugins:, admin_root_types:, admin_root_name:, layout:
      }
    end

    def hook_counts
      hooks.instance_variable_get(:@registry).transform_values(&:size)
    end

    def default_admin_recording_resolver
      lambda do
        klass = Array(admin_root_types).first&.safe_constantize
        next unless klass.respond_to?(:find_by)

        root = klass.find_by(name: admin_root_name)
        next unless root

        RecordingStudio::Recording.where(
          RecordingStudio::Recording.recording_studio_trashable_kept_sql
        ).find_by(recordable: root)
      end
    end
  end

  Configuration.include ActorLabelConfig
  Configuration.include LayoutConfig
  Configuration.include ConfigSources

  module Override
    OVERRIDE_KEYS = %i[name description category position].freeze

    module_function

    def normalize(override)
      return {} unless override.respond_to?(:to_h)

      raw = override.to_h.transform_keys(&:to_sym)
      {
        name: text(raw, :name),
        description: text(raw, :description),
        category: symbol(raw, :category),
        position: number(raw, :position)
      }.slice(*OVERRIDE_KEYS).compact
    end

    def text(raw, key)
      raw[key].to_s if present?(raw, key)
    end

    def symbol(raw, key)
      raw[key].to_sym if present?(raw, key)
    end

    def number(raw, key)
      Integer(raw[key]) if present?(raw, key)
    end

    def present?(raw, key)
      raw.key?(key) && !raw[key].nil?
    end
  end
end
