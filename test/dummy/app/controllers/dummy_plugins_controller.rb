# frozen_string_literal: true

class DummyPluginsController < ApplicationController
  def connect
    redirect_to recording_studio_plugins.root_path
  end
end
