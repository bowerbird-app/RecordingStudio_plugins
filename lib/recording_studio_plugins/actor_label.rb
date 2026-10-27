# frozen_string_literal: true

module RecordingStudioPlugins
  module ActorLabel
    module_function

    def call(actor)
      return "User" if actor.nil?

      named = actor.respond_to?(:name) ? actor.name : nil
      return named if named.present?

      emailed = actor.respond_to?(:email) ? actor.email : nil
      return emailed if emailed.present?

      "User"
    end
  end
end
