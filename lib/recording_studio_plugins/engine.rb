# frozen_string_literal: true

module RecordingStudioPlugins
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioPlugins

    initializer "recording_studio_plugins.shipped_english", before: "recording_studio.load_shipped_english" do
      RecordingStudio::Translation.register_shipped_english(
        RecordingStudioPlugins::Engine.root.join("config/locales/en.yml")
      )
    end

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioPlugins.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_plugins_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_plugins_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    # Run before_initialize hooks
    initializer "recording_studio_plugins.before_initialize", before: "recording_studio_plugins.load_config" do |_app|
      RecordingStudioPlugins.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_plugins.load_config" do |app|
      RecordingStudioPlugins.configuration.load_from_rails_app!(app)
      RecordingStudioPlugins.configuration.hooks.run(:on_configuration, RecordingStudioPlugins.configuration)
    end

    # Run after_initialize hooks
    initializer "recording_studio_plugins.after_initialize", after: "recording_studio_plugins.load_config" do |_app|
      RecordingStudioPlugins.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_plugins.admin_definitions" do
      config.to_prepare do
        RecordingStudioPlugins::PluginAppearance.declare_hierarchy!
        RecordingStudioPlugins::Admin.register!
      end
    end

    # Apply model extensions when models are loaded
    initializer "recording_studio_plugins.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioPlugins::Engine.apply_model_extensions(model)
        end
      end
    end

    # Apply controller extensions
    initializer "recording_studio_plugins.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioPlugins::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
