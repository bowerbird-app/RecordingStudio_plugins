# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioPlugins
  module Admin
    class PluginsSection < RecordingStudioAdmin::Section
      key "plugins"
      icon :squares_2x2
      title "Plugins"
      subtitle "Names and pictures people see in the directory."
      blast_radius :site

      link :edit,
           text: "Edit names and pictures",
           url: ->(context) { RecordingStudioPlugins.admin_plugins_path(context) },
           style: :primary
    end

    class PluginsResource < RecordingStudioAdmin::Resource
      key "plugins"
      section "plugins"
      title "Plugin names and pictures"

      action :show,
             text: "Plugin names and pictures",
             icon: "squares-2x2",
             url: ->(_row, context) { RecordingStudioPlugins.admin_plugins_path(context) }

      action :edit,
             text: "Save",
             icon: "pencil-square",
             required_role: :admin,
             url: ->(_row, context) { RecordingStudioPlugins.admin_plugins_path(context) }
    end

    def self.register!
      RecordingStudioAdmin.register_section(PluginsSection)
      RecordingStudioAdmin.register_resource(PluginsResource)
    end
  end
end
