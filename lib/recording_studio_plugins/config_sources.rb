# frozen_string_literal: true

module RecordingStudioPlugins
  module ConfigSources
    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end

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
end
