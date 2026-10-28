# frozen_string_literal: true

module RecordingStudioPlugins
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
