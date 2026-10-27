# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    class AppearancesController < ApplicationController
      include StaffAccess

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

        ensure_appearance_recording!(definition) if plugin_staff_admin?
        @row = appearance_row(definition)
      end

      def update
        authorize_plugin_staff!(role: :admin)
        definition = plugin_definition
        unless definition
          head :not_found
          return
        end

        save_appearance(definition.key)
        redirect_to admin_plugins_path, notice: helpers.plugin_copy("admin.flashes.saved")
      end

      def destroy_image
        authorize_plugin_staff!(role: :admin)
        Appearance.remove_image!(params[:key], actor: staff_actor)
        redirect_to admin_plugin_edit_path(params[:key]), notice: helpers.plugin_copy("admin.flashes.picture_removed")
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

      def ensure_appearance_recording!(definition)
        Appearance.ensure_recording!(definition.key, actor: staff_actor)
      end

      def plugin_definition
        definition = RecordingStudioPlugins.find(params[:key])
        return if definition.nil? || RecordingStudioPlugins.configuration.hidden?(definition.key)

        definition
      end

      def save_appearance(key)
        Appearance.update_name!(key, name: appearance_name_param(key), actor: staff_actor)
        save_picture(key)
      end

      def save_picture(key)
        upload = appearance_picture_param(key)
        return replace_uploaded_picture(key, upload) if upload
        return unless appearance_remove_picture?(key)

        Appearance.remove_image!(key, actor: staff_actor)
      end

      def replace_uploaded_picture(key, upload)
        Appearance.replace_image!(key, file: upload, actor: staff_actor)
      end

      def appearance_name_param(key)
        appearance_attrs(key)["name"]
      end

      def appearance_picture_param(key)
        upload = appearance_attrs(key)["picture"]
        return unless upload.respond_to?(:original_filename) && upload.original_filename.present?

        upload
      end

      def appearance_remove_picture?(key)
        appearance_attrs(key)["remove_picture"].to_s == "1"
      end

      def appearance_attrs(key)
        raw = params[:appearances]
        return {} if raw.blank?

        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        attrs = hash.stringify_keys[key.to_s]
        return {} if attrs.blank?
        return attrs.stringify_keys if attrs.respond_to?(:stringify_keys)

        {}
      end
    end
  end
end
