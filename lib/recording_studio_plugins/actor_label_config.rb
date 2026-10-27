# frozen_string_literal: true

module RecordingStudioPlugins
  module ActorLabelConfig
    def actor_label
      @actor_label || ActorLabel
    end

    def actor_label=(callable)
      if callable.nil?
        @actor_label = nil
        return
      end

      raise ArgumentError, "actor_label must respond to call" unless callable.respond_to?(:call)

      @actor_label = callable
    end
  end
end
