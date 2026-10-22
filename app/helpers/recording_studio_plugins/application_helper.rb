# frozen_string_literal: true

module RecordingStudioPlugins
  module ApplicationHelper
    def plugin_badge(listing)
      return if listing.badge_style.nil?

      render FlatPack::Badge::Component.new(text: listing.badge_text, style: listing.badge_style, size: :sm)
    end

    def plugin_action(listing, can_edit:)
      return unless listing.action?(can_edit: can_edit)

      render FlatPack::Button::Component.new(
        text: listing.action_label,
        style: :primary,
        href: listing.action_href,
        target: (listing.action_external? ? "_blank" : nil)
      )
    end

    def plugin_paragraphs(text)
      text.to_s.split(/\n\n+/).map(&:strip).reject(&:empty?)
    end

    def plugin_copy(key, default: nil)
      RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
    end
  end
end
