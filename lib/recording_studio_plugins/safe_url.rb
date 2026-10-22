# frozen_string_literal: true

require "uri"

module RecordingStudioPlugins
  module SafeUrl
    module_function

    def allowed(value)
      text = value.to_s.strip
      return if text.empty?
      return if text.match?(/\A(?:javascript|data|vbscript|http):/i)
      return if text.start_with?("//", "\\")
      return https_url(text) if text.match?(/\Ahttps:/i)
      return path_url(text) if text.start_with?("/")

      nil
    end

    def external?(value)
      allowed(value).to_s.start_with?("https://")
    end

    def https_url(text)
      return unless text.match?(%r{\Ahttps://}i)

      uri = URI.parse(text)
      return if uri.userinfo
      return if uri.host.nil? || uri.host.empty?
      return unless uri.scheme == "https"

      text
    rescue URI::InvalidURIError
      nil
    end

    def path_url(text)
      return if text.start_with?("//")
      return if text.match?(/[\s\\]/)

      text
    end
    private_class_method :https_url, :path_url
  end
end
