# frozen_string_literal: true

require "test_helper"

class CurrentActorTest < Minitest::Test
  def test_prefers_current_actor_when_present
    previous = defined?(Current) && Current.respond_to?(:actor) ? Current.actor : nil
    skip "Current.actor is not available" unless defined?(Current) && Current.respond_to?(:actor)

    Current.actor = :from_current
    controller = Object.new
    def controller.current_user
      :from_user
    end

    assert_equal :from_current, RecordingStudioPlugins::CurrentActor.resolve(controller)
  ensure
    Current.actor = previous if defined?(Current) && Current.respond_to?(:actor=)
  end

  def test_falls_back_to_current_user
    previous = defined?(Current) && Current.respond_to?(:actor) ? Current.actor : nil
    Current.actor = nil if defined?(Current) && Current.respond_to?(:actor=)
    controller = Object.new
    def controller.current_user
      :from_user
    end

    assert_equal :from_user, RecordingStudioPlugins::CurrentActor.resolve(controller)
  ensure
    Current.actor = previous if defined?(Current) && Current.respond_to?(:actor=)
  end
end
