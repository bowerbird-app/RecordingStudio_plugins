# frozen_string_literal: true

module RecordingStudioPlugins
  class Definition
    FIELDS = %i[key name description category icon provider position owner].freeze

    attr_reader(*FIELDS)

    def self.build(**attributes)
      require_text(attributes, :key)
      require_text(attributes, :name)
      require_text(attributes, :owner)
      assert_category(attributes[:category])
      new(**attributes)
    end

    def self.require_text(attributes, field)
      value = attributes[field]
      raise ArgumentError, "#{field} is required" if value.nil? || value.to_s.strip.empty?
    end

    def self.assert_category(category)
      return if RecordingStudioPlugins.configuration.category?(category)

      raise UnknownCategory, "#{category} is not a plugin category"
    end

    def initialize(**attributes)
      coerced = self.class.coerce(attributes)
      FIELDS.each { |field| instance_variable_set(:"@#{field}", coerced[field]) }
    end

    def self.coerce(attributes)
      {
        key: attributes[:key].to_sym,
        name: attributes[:name].to_s,
        description: attributes[:description].to_s,
        category: attributes[:category].to_sym,
        icon: attributes[:icon].to_s,
        provider: attributes[:provider],
        position: Integer(attributes[:position]),
        owner: attributes[:owner].to_s
      }
    end

    def override(values)
      return self if values.nil? || values.empty?

      self.class.new(**to_h, **values)
    end

    def to_h
      FIELDS.to_h { |field| [field, public_send(field)] }
    end
  end
end
