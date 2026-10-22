# frozen_string_literal: true

module RecordingStudioPlugins
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)
    helper RecordingStudioPlugins::ApplicationHelper
    helper RecordingStudio::LayoutHelper if defined?(RecordingStudio::LayoutHelper)

    if defined?(Rails.application) && Rails.application.respond_to?(:root)
      prepend_view_path Rails.application.root.join("app/views")
    end
    append_view_path RecordingStudio::Engine.root.join("app/views") if defined?(RecordingStudio::Engine)

    layout "recording_studio/default_layout"

    before_action :ensure_flatpack_application_stylesheet

    protect_from_forgery with: :exception

    private

    def ensure_flatpack_application_stylesheet
      return unless respond_to?(:view_context)

      view_context.content_for(
        :head,
        helpers.stylesheet_link_tag("flat_pack/application", "data-turbo-track": "reload")
      )
    end
  end
end
