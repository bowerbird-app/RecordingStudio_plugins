# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    class AppearancesController < ApplicationController
      include StaffAccess

      helper AppearancesHelper
      helper RecordingStudioAttachable::ApplicationHelper
      helper Rails.application.routes.mounted_helpers
      helper_method :recording_direct_uploads_path

      def index
        unless Appearance.configured?
          @unconfigured = true
          @rows = []
          return
        end

        assign_rows
      end

      def edit
        definition = plugin_definition
        unless definition
          head :not_found
          return
        end

        @row = appearance_row(definition)
      end

      def update
        authorize_plugin_staff!(role: :admin)
        definition = plugin_definition
        unless definition
          head :not_found
          return
        end

        save_name(definition.key)
        redirect_to admin_plugins_path, notice: plugin_copy("admin.flashes.saved")
      end

      def destroy_image
        authorize_plugin_staff!(role: :admin)
        Appearance.remove_image!(params[:key], actor: staff_actor)
        redirect_to admin_plugin_edit_path(params[:key]), notice: plugin_copy("admin.flashes.picture_removed")
      end

      private

      def assign_rows
        @rows = RecordingStudioPlugins.all.map { |definition| appearance_row(definition) }
      end

      def appearance_row(definition)
        key = definition.key
        recording = Appearance.recording_for(key)
        {
          definition:, key:, registered_name: definition.name, recording:,
          name: Appearance.display_name(definition), custom_name: recording&.recordable&.name,
          image_url: Appearance.image_url(definition), attachment_recording: Appearance.image_recording(key)
        }
      end

      def plugin_definition
        definition = RecordingStudioPlugins.find(params[:key])
        return if definition.nil? || RecordingStudioPlugins.configuration.hidden?(definition.key)

        definition
      end

      def save_name(key)
        attrs = appearance_params[key.to_s] || appearance_params[key.to_sym]
        Appearance.update_name!(key, name: attrs&.fetch(:name, nil), actor: staff_actor)
      end

      def appearance_params
        raw = params[:appearances]
        return {} if raw.blank?

        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.each_with_object({}) do |(key, attrs), allowed|
          next unless key.to_s.match?(/\A[a-z][a-z0-9_]*\z/)

          values = attrs.respond_to?(:to_h) ? attrs.to_h : {}
          allowed[key] = { name: values["name"] || values[:name] }
        end
      end

      def recording_direct_uploads_path(recording, **)
        recording_studio_attachable.recording_direct_uploads_path(recording, **)
      end
    end
  end
end
