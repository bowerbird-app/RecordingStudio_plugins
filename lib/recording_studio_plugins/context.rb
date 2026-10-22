# frozen_string_literal: true

module RecordingStudioPlugins
  class Context
    attr_reader :actor, :root_recording, :request

    def initialize(actor:, root_recording:, request: nil)
      @actor = actor
      @root_recording = root_recording
      @request = request
      @results = {}
    end

    def call_provider(definition, method_name)
      cache_key = [definition.key, method_name]
      return @results[cache_key] if @results.key?(cache_key)

      @results[cache_key] = invoke(definition, method_name)
    end

    private

    def invoke(definition, method_name)
      provider = definition.provider
      return :missing if provider.nil? || !provider.respond_to?(method_name)

      provider.public_send(method_name, self)
    rescue StandardError => e
      RecordingStudioPlugins.log_provider_failure(definition.key, method_name, e)
      :raised
    end
  end
end
