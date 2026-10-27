# frozen_string_literal: true

module RecordingStudioPlugins
  module LayoutConfig
    def layout
      @layout ||= nil
    end

    def layout=(value)
      @layout = RecordingStudio::Layout.accept(value)
    end
  end
end
