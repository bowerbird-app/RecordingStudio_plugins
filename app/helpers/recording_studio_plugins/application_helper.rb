# frozen_string_literal: true

module RecordingStudioPlugins
  module ApplicationHelper
    include PluginIcons

    DIRECTORY_ROW_CLASSES = [
      "flex items-center",
      "rounded-[var(--radius-sm)]",
      "py-[var(--list-item-padding-y)] px-[var(--list-item-padding-x)]",
      "text-[var(--surface-content-color)]"
    ].join(" ").freeze

    def plugin_copy(key, default: nil, **interpolations)
      RecordingStudio.t("recording_studio.plugins.#{key}", default: default, **interpolations)
    end

    def plugin_badge(listing)
      return if listing.badge_style.nil?

      render FlatPack::Badge::Component.new(text: listing.badge_text, style: listing.badge_style, size: :sm)
    end

    def plugin_directory_status(listing)
      return plugin_inbound_status(listing) if listing.user?
      return if listing.root? && listing.badge_style == :success

      plugin_badge(listing)
    end

    def plugin_inbound_status(listing)
      return if listing.directory_status_text.blank?

      parts = [tag.span(listing.directory_status_text)]
      parts << tag.span(listing.people_connected_text) if listing.people_connected_text.present?
      tag.span(safe_join(parts, " "), class: "inline-flex items-center gap-2")
    end

    def plugin_setup_button(listing)
      href = listing.setup_href
      return if href.blank?

      render FlatPack::Button::Component.new(
        text: listing.directory_status_text.presence || plugin_copy("status.connect"),
        style: :secondary,
        href: href,
        target: "_blank"
      )
    end

    def plugin_directory_row(trailing:, &)
      tag.li(class: DIRECTORY_ROW_CLASSES, role: "listitem") do
        leading = tag.div(class: "min-w-0 flex-1 flex items-center", &)
        action = tag.span(trailing, class: "flex-shrink-0 ml-2") if trailing.present?
        safe_join([leading, action].compact)
      end
    end

    def plugin_inbound_modal_id(listing)
      "plugin-#{listing.key}-people"
    end

    def plugin_inbound_people_frame_id(listing)
      "#{plugin_inbound_modal_id(listing)}-frame"
    end

    def plugin_people_rows(people)
      Array(people).map do |row|
        {
          name: row[:name],
          email: row[:email].presence || "—",
          role: row[:role].to_s.humanize,
          connected_since: plugin_time(row[:connected_at]),
          last_used: plugin_time(row[:last_used_at])
        }
      end
    end

    def plugin_time(value)
      return plugin_copy("detail.never") if value.blank?

      exact = I18n.l(value, format: :long)
      render FlatPack::Tooltip::Component.new(text: exact, placement: :top) do
        tag.time("#{time_ago_in_words(value)} ago", datetime: value.iso8601, tabindex: 0, aria: { label: exact })
      end
    end

    def plugin_action(listing, can_edit:, can_admin: false, directory: false)
      return if listing.user?

      allowed = listing.root? ? can_admin : can_edit
      return unless listing.action?(can_edit: allowed)

      if listing.root?
        render "recording_studio_plugins/plugins/oauth_action", listing: listing, directory: directory
      else
        render FlatPack::Button::Component.new(**plugin_action_attributes(listing))
      end
    end

    def plugin_action_attributes(listing)
      {
        text: listing.action_label,
        style: :primary,
        href: listing.action_href,
        target: (listing.action_external? ? "_blank" : nil)
      }
    end

    def plugin_oauth_button_style(connected_row, directory:)
      return :secondary if directory
      return :danger if connected_row

      :primary
    end

    def plugin_admin_edit_cell(row)
      render FlatPack::Link::Component.new(href: admin_plugin_edit_path(row[:key])) do
        plugin_copy("admin.edit")
      end
    end
  end
end
