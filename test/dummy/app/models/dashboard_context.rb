# frozen_string_literal: true

class DashboardContext
  attr_reader :actor, :root_recording, :request

  def initialize(actor:, root_recording:, request: nil)
    @actor = actor
    @root_recording = root_recording
    @request = request
  end
end
