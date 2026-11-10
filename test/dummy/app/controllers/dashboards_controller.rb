# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @context = DashboardContext.new(
      actor: current_user,
      root_recording: current_root_recording,
      request: request
    )
  end
end
