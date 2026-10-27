# frozen_string_literal: true

require "recording_studio_plugins/safe_url"

module RecordingStudioPlugins
  class Definition
    FIELDS = %i[key name description category icon provider position owner kind setup_url].freeze

    attr_reader(*FIELDS)

    def self.build(**attributes)
      require_text(attributes, :key)
      require_text(attributes, :name)
      require_text(attributes, :owner)
      assert_category(attributes[:category])
      assert_setup_url(attributes[:setup_url])
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

    def self.assert_setup_url(value)
      return if value.nil? || value.to_s.strip.empty?
      return if SafeUrl.https_only(value)

      raise ArgumentError, "setup_url must be an https URL"
    end

    def initialize(**attributes)
      coerced = self.class.coerce(attributes)
      FIELDS.each { |field| instance_variable_set(:"@#{field}", coerced[field]) }
    end

    def self.coerce(attributes)
      typed_fields(attributes).merge(
        kind: attributes[:kind]&.to_sym,
        setup_url: attributes[:setup_url].to_s
      )
    end

    def self.typed_fields(attributes)
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
    private_class_method :typed_fields

    def root?
      kind == :root
    end

    def user?
      kind == :user
    end

    def override(values)
      allowed = Override.normalize(values)
      return self if allowed.empty?

      self.class.new(**to_h, **allowed)
    end

    def to_h
      FIELDS.to_h { |field| [field, public_send(field)] }
    end
  end
end
