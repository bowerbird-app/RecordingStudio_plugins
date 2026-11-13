# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module RootSwitchableViewGrant
  # Root Switchable 0.15 refuses the switch page unless the actor has
  # Accessible :view on the current root. The dummy scope's current root is
  # the first workspace by name.
  def grant_view_on_current_switch_root!(actor)
    return if actor.blank?

    recording = Workspace.order(:name).filter_map { |workspace|
      RecordingStudio.root_recording_for(workspace)
    }.first
    return if recording.blank?
    return if RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)

    previous_actor = Current.actor
    manager = User.all.find do |candidate|
      candidate != actor &&
        RecordingStudioAccessible.authorized?(actor: candidate, recording: recording, role: :admin)
    end

    begin
      if manager
        Current.actor = manager
        result = RecordingStudioAccessible.grant_access(
          recording: recording,
          actor: actor,
          role: "view",
          manager_actor: manager
        )
        raise result.error if result.respond_to?(:failure?) && result.failure?
      else
        Current.actor = actor
        RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
      end
    ensure
      Current.actor = previous_actor
    end
  end
end

ActionDispatch::IntegrationTest.include RootSwitchableViewGrant
