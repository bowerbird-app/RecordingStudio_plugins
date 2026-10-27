# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    class AppearancesController < ApplicationController
      include AppearanceAccess

      helper RecordingStudioAttachable::ApplicationHelper
      helper Rails.application.routes.mounted_helpers
      helper_method :recording_direct_uploads_path
      helper_method :recording_studio_admin_context, :plugin_admin_back_href

      before_action :authorize_plugin_staff!
      rescue_from RecordingStudioAdmin::AuthorizationFailed, with: :render_staff_forbidden
      rescue_from RecordingStudioAdmin::DefinitionNotFound, with: :render_staff_forbidden

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

        prepare_edit_recording!(definition)
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

      def prepare_edit_recording!(definition)
        return unless Appearance.configured? && staff_can_change_appearance?

        Appearance.ensure_recording!(definition.key, actor: staff_actor)
      end

      def save_name(key)
        attrs = appearance_params[key.to_s] || appearance_params[key.to_sym]
        name = attrs&.[](:name) || attrs&.[]("name")
        Appearance.update_name!(key, name: name, actor: staff_actor)
      end

      def appearance_params
        raw = params[:appearances]
        return {} if raw.blank?

        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.each_with_object({}) do |(key, attrs), allowed|
          next unless key.to_s.match?(/\A[a-z][a-z0-9_]*\z/)

          values = appearance_value_hash(attrs)
          allowed[key] = { name: values["name"] || values[:name] }
        end
      end

      def appearance_value_hash(attrs)
        return attrs.to_unsafe_h if attrs.respond_to?(:to_unsafe_h)
        return attrs.to_h if attrs.respond_to?(:to_h)

        {}
      end

      def plugin_copy(key, default: nil)
        RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
      end

      def recording_direct_uploads_path(recording, **)
        recording_studio_attachable.recording_direct_uploads_path(recording, **)
      end
    end
  end
end
