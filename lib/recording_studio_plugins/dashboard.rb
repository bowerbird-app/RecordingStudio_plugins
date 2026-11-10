# frozen_string_literal: true

module RecordingStudioPlugins
  module Dashboard
    WIDGET_ID = :installable_plugins

    class << self
      def register!
        return unless defined?(::RecordingStudioDashboard)

        require "recording_studio_plugins/dashboard/installable_plugins"
        register_widget unless widget_registered?
      end

      private

      def register_widget
        ::RecordingStudioDashboard.register_widget(WIDGET_ID, **widget_registration)
      end

      def widget_registration
        {
          component: InstallablePlugins::Component,
          default_span: 12,
          empty: :message,
          empty_message: InstallablePlugins.empty_message,
          permission: InstallablePlugins.method(:visible?)
        }
      end

      def widget_registered?
        return false unless ::RecordingStudioDashboard.respond_to?(:registry)

        ::RecordingStudioDashboard.registry.widget(WIDGET_ID)
        true
      rescue KeyError, NoMethodError
        false
      end
    end
  end
end
