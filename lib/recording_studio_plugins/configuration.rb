# frozen_string_literal: true

module RecordingStudioPlugins
  module ConfigurationRailsLoad
    def load_from_rails_app!(app)
      merge_config_for(app)
      merge_x_config(app)
    end

    private

    def merge_config_for(app)
      return unless app.respond_to?(:config_for)

      yaml = app.config_for(:recording_studio_plugins)
      merge!(yaml) if yaml.respond_to?(:each)
    rescue StandardError
      nil
    end

    def merge_x_config(app)
      xcfg = rails_x_config(app)
      return if xcfg.nil?

      merge!(x_config_hash(xcfg))
    rescue StandardError
      nil
    end

    def rails_x_config(app)
      return unless app.config.respond_to?(:x)
      return unless app.config.x.respond_to?(:recording_studio_plugins)

      app.config.x.recording_studio_plugins
    end

    def x_config_hash(xcfg)
      return xcfg.to_h if xcfg.respond_to?(:to_h)
      return {} unless xcfg.respond_to?(:each_pair)

      hash = {}
      xcfg.each_pair { |key, value| hash[key] = value }
      hash
    end
  end

  class Configuration
    include ConfigurationRailsLoad

    DEFAULT_CATEGORIES = %i[ai_agents storage social websites automation other].freeze

    attr_reader :hooks, :layout
    attr_accessor :mount_path

    def initialize
      @mount_path = "/recording_studio_plugins"
      @hidden_keys = []
      @overrides = {}
      @extra_categories = []
      @enabled_plugins = []
      @layout = nil
      @hooks = RecordingStudio::Hooks.new
    end

    def layout=(value)
      @layout = RecordingStudio::Layout.accept(value)
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
      {
        mount_path: mount_path,
        hidden_keys: hidden_keys,
        overrides: overrides,
        extra_categories: extra_categories,
        enabled_plugins: enabled_plugins,
        layout: layout,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end
  end

  Configuration.include ActorLabelConfig

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
