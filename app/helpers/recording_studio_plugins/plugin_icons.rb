# frozen_string_literal: true

module RecordingStudioPlugins
  module PluginIcons
    def plugin_admin_picture_cell(row)
      plugin_icon(image_url: row[:image_url], alt: row[:name], size: :sm)
    end

    def plugin_image(listing, size: :md)
      plugin_icon(image_url: listing.image_url, alt: listing.name, size: size)
    end

    def plugin_icon(image_url:, alt:, size: :sm)
      return plugin_picture_avatar(image_url, alt, size) if image_url.present?

      plugin_placeholder_avatar(size)
    end

    def plugin_picture_avatar(image_url, alt, size)
      render FlatPack::Avatar::Component.new(src: image_url, size: size, shape: :square, alt: alt)
    end

    def plugin_placeholder_avatar(size)
      render FlatPack::Avatar::Component.new(
        size: size,
        shape: :square,
        icon: "puzzle-piece",
        alt: "",
        show_tooltip: false,
        aria: { hidden: true }
      )
    end
  end
end
