# frozen_string_literal: true

module RecordingStudioPlugins
  module ApplicationHelper
    def plugin_badge(listing)
      return if listing.badge_style.nil?

      render FlatPack::Badge::Component.new(text: listing.badge_text, style: listing.badge_style, size: :sm)
    end

    def plugin_action(listing, can_edit:, can_admin: false)
      allowed = listing.root? ? can_admin : can_edit
      return unless listing.action?(can_edit: allowed)

      render FlatPack::Button::Component.new(
        **plugin_action_attributes(listing)
      )
    end

    def plugin_action_attributes(listing)
      attributes = {
        text: listing.action_label,
        style: listing.action_method == :delete ? :danger : :primary,
        href: listing.action_href,
        target: (listing.action_external? ? "_blank" : nil)
      }
      attributes[:method] = listing.action_method if listing.action_method
      attributes
    end

    def plugin_paragraphs(text)
      text.to_s.split(/\n\n+/).map(&:strip).reject(&:empty?)
    end

    def plugin_copy(key, default: nil)
      RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
    end
  end
end
