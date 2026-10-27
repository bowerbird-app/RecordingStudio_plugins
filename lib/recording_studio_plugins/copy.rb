# frozen_string_literal: true

require "cgi"

module RecordingStudioPlugins
  module Copy
    def plugin_copy(key, default: nil)
      text = RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
      return text unless text.is_a?(String)

      # RecordingStudio.t leaves non-_html keys unsafe. PageTitle and
      # SectionTitle then HTML-escape them. A second pass (content_for plus
      # layout `.strip`, which drops html_safe) turns `'` into a visible `&#39;`.
      CGI.unescapeHTML(text.to_s).html_safe
    end
  end
end
