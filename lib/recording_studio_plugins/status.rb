# frozen_string_literal: true

module RecordingStudioPlugins
  class Status
    STATES = %i[connected attention].freeze

    attr_reader :state, :message, :action_label, :action_url

    def initialize(state: nil, message: nil, action_label: nil, action_url: nil)
      @state = normalize_state(state)
      @message = presence(message)
      @action_label = presence(action_label)
      @action_url = presence(action_url)
    end

    def connected?
      state == :connected
    end

    def attention?
      state == :attention
    end

    private

    def normalize_state(state)
      return if state.nil? || state.to_s.strip.empty?

      symbol = state.to_sym
      STATES.include?(symbol) ? symbol : nil
    end

    def presence(value)
      text = value.to_s
      text.strip.empty? ? nil : text
    end
  end
end
