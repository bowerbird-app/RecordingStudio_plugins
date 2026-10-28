# frozen_string_literal: true

module RecordingStudioPlugins
  module CurrentActor
    module_function

    def resolve(controller)
      if defined?(::Current) && ::Current.respond_to?(:actor) && ::Current.actor
        ::Current.actor
      elsif controller.respond_to?(:current_user)
        controller.current_user
      end
    end
  end
end
