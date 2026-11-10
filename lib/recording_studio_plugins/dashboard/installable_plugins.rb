# frozen_string_literal: true

module RecordingStudioPlugins
  module Dashboard
    module InstallablePlugins
      CardItem = Data.define(:key, :name, :image_url, :href, :external)

      class << self
        def prepare(context, _config)
          cards = card_items(context)
          return ::RecordingStudioDashboard::Preparation.empty(message: empty_message) if cards.empty?

          ::RecordingStudioDashboard::Preparation.content(cards)
        end

        def visible?(context)
          actor = read(context, :actor)
          root = read(context, :root_recording)
          return false if actor.blank? || root.blank?
          return true unless defined?(::RecordingStudioAccessible)

          ::RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :view)
        rescue StandardError
          # Permission runs outside the dashboard's prepare rescue. A raise drops every widget.
          false
        end

        def empty_message
          copy("dashboard.empty")
        end

        def card_items(context)
          listings_for(context).reject(&:connected?).map { |listing| card_item(listing) }
        end

        private

        def listings_for(context)
          RecordingStudioPlugins.listings_for(context: plugin_context_for(context))
        end

        def plugin_context_for(context)
          Context.new(
            actor: read(context, :actor),
            root_recording: read(context, :root_recording),
            request: read(context, :request)
          )
        end

        def card_item(listing)
          href = listing.setup_href.presence || directory_href
          CardItem.new(
            key: listing.key,
            name: listing.name,
            image_url: listing.image_url,
            href: href,
            external: listing.setup_href.present?
          )
        end

        def directory_href
          path = RecordingStudioPlugins.configuration.mount_path.to_s
          path = "/recording_studio_plugins" if path.empty?
          path.end_with?("/") ? path : "#{path}/"
        end

        def read(context, name)
          return if context.nil? || !context.respond_to?(name)

          context.public_send(name)
        rescue StandardError
          nil
        end

        def copy(key)
          RecordingStudio.t("recording_studio.plugins.#{key}")
        end
      end

      class Component
        def self.prepare(context, config)
          InstallablePlugins.prepare(context, config)
        end

        def self.new(context:, config:, preparation:)
          card.new(context: context, config: config, preparation: preparation)
        end

        def self.card
          require "recording_studio_plugins/dashboard/installable_plugins/component"
          Card
        end
        private_class_method :card
      end
    end
  end
end
