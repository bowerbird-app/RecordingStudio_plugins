# frozen_string_literal: true

module RecordingStudioPlugins
  class Registry
    def initialize
      @definitions = {}
    end

    def register(definition)
      existing = @definitions[definition.key]
      if existing && existing.owner != definition.owner
        raise RegistryConflict, "#{definition.key} is already registered for #{existing.owner}"
      end

      @definitions[definition.key] = definition
      definition
    end

    def find(key)
      return if key.nil? || key.to_s.strip.empty?

      @definitions[key.to_sym]
    end

    def all
      @definitions.values
    end

    def clear!
      @definitions.clear
    end
  end
end
