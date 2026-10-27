# frozen_string_literal: true

require "recording_studio_plugins/listing/root_action"
require "recording_studio_plugins/listing/inbound"

module RecordingStudioPlugins
  class Listing
    include RootAction
    include Inbound

    delegate :key, :name, :description, :icon, :category, :position, :kind, :root?, :user?, to: :definition

    attr_reader :definition

    def initialize(definition, plugin_context)
      @definition = definition
      @plugin_context = plugin_context
    end

    def listed?
      plugin_context.call_provider(definition, :available?) != false
    end

    def badge_style
      return if status_failed?
      return :success if connected?
      return :warning if attention?

      nil
    end

    def badge_text
      return copy("status.connected") if connected?
      return copy("status.attention") if attention?

      nil
    end

    def message
      return status_record&.message if user?
      return unless attention?

      status_record.message
    end

    def action?(can_edit:)
      return false if user?
      return false unless can_edit
      return false if status_failed? || (connected? && action_href.blank?)
      return false if rejected_action_url?

      true
    end

    def action_label
      status_record&.action_label.presence || copy("status.setup")
    end

    def action_href
      SafeUrl.allowed(status_record&.action_url)
    end

    def action_external?
      SafeUrl.external?(action_href)
    end

    def about
      text_for(:about)
    end

    def setup_instructions
      text_for(:setup_instructions)
    end

    def usage_instructions
      text_for(:usage_instructions)
    end

    def documentation_url
      SafeUrl.allowed(text_for(:documentation_url))
    end

    def documentation_external?
      SafeUrl.external?(documentation_url)
    end

    private

    attr_reader :plugin_context

    def connected?
      status_record&.connected?
    end

    def attention?
      status_record&.attention?
    end

    def status_record
      status_result if status_result.is_a?(Status)
    end

    def status_failed?
      status_result == :raised || unexpected_status?
    end

    def unexpected_status?
      return false if status_result.nil? || status_result == :missing || status_result.is_a?(Status)

      true
    end

    def rejected_action_url?
      raw = status_record&.action_url
      raw.present? && action_href.nil?
    end

    def status_result
      return @status_result if defined?(@status_result)

      @status_result = plugin_context.call_provider(definition, :status)
    end

    def text_for(method_name)
      result = plugin_context.call_provider(definition, method_name)
      return if result.nil? || result == :missing || result == :raised

      result.to_s
    end

    def copy(key, default: nil)
      RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
    end
  end
end
