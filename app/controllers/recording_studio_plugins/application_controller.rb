# frozen_string_literal: true

module RecordingStudioPlugins
  # `defined?` does not autoload. Eager load opens this file before the host controller.
  host_application_controller = ActionController::Base
  if defined?(Rails) && Rails.application
    controller_file = Rails.application.root.join("app/controllers/application_controller.rb")
    host_application_controller = ::ApplicationController if controller_file.file?
  end

  class ApplicationController < host_application_controller
    helper RecordingStudioPlugins::ApplicationHelper
    helper RecordingStudio::LayoutHelper if defined?(RecordingStudio::LayoutHelper)

    if defined?(Rails.application) && Rails.application.respond_to?(:root)
      prepend_view_path Rails.application.root.join("app/views")
    end
    append_view_path RecordingStudio::Engine.root.join("app/views") if defined?(RecordingStudio::Engine)

    recording_studio_layout { RecordingStudioPlugins.configuration.layout }

    protect_from_forgery with: :exception
  end
end
