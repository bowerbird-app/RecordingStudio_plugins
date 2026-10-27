# frozen_string_literal: true

module RecordingStudioPlugins
  class PluginsController < ApplicationController
    before_action :require_directory_access

    helper_method :can_edit_plugins?, :can_admin_plugins?

    def index
      @listings = RecordingStudioPlugins.listings_for(context: plugin_context)
    end

    def show
      @listing = directory_listing
      unless @listing
        head :not_found
        return
      end

      @people = @listing.inbound_people if @listing.user? && can_admin_plugins?
    end

    private

    def require_directory_access
      return if directory_allowed?(:view)

      render "forbidden", status: :forbidden
    end

    def directory_allowed?(role)
      root = directory_root
      actor = directory_actor
      root.present? && actor.present? &&
        RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: role)
    end

    def directory_root
      return unless respond_to?(:current_root_recording)

      current_root_recording
    end

    def directory_actor
      if defined?(Current) && Current.respond_to?(:actor) && Current.actor
        Current.actor
      elsif respond_to?(:current_user)
        current_user
      end
    end

    def plugin_context
      @plugin_context ||= Context.new(
        actor: directory_actor,
        root_recording: directory_root,
        request: request
      )
    end

    def directory_listing
      definition = RecordingStudioPlugins.find(params[:key])
      return if definition.nil? || RecordingStudioPlugins.configuration.hidden?(definition.key)
      return unless OauthDirectory.visible?(definition, plugin_context)

      listing = Listing.new(definition, plugin_context)
      listing if listing.listed?
    end

    def can_edit_plugins?
      directory_allowed?(:edit)
    end

    def can_admin_plugins?
      directory_allowed?(:admin)
    end
  end
end
