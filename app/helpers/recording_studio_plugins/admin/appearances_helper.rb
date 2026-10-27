# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    module AppearancesHelper
      def plugin_appearance_picture(row)
        return if row[:image_url].blank?

        render FlatPack::Avatar::Component.new(
          src: row[:image_url],
          size: :sm,
          shape: :square,
          alt: row[:name]
        )
      end

      def plugin_appearance_edit_link(row)
        render FlatPack::Link::Component.new(href: admin_plugin_edit_path(row[:key])) do
          plugin_copy("admin.edit")
        end
      end
    end
  end
end
