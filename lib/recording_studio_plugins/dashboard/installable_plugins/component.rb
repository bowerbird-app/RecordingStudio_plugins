# frozen_string_literal: true

require "view_component"

module RecordingStudioPlugins
  module Dashboard
    module InstallablePlugins
      class Card < ViewComponent::Base
        include PluginIcons

        def initialize(context:, config:, preparation:)
          super()
          @context = context
          @config = config
          @preparation = preparation
        end

        def call
          render(FlatPack::Grid::Component.new(cols: column_count, gap: :sm)) do
            safe_join(items.map { |item| plugin_card(item) })
          end
        end

        private

        def items
          Array(@preparation.data)
        end

        def column_count
          count = items.size
          return 1 if count < 1

          [count, 4].min
        end

        def plugin_card(item)
          render(FlatPack::Card::Component.new(**card_attributes(item))) do |card|
            card.body { card_inner(item) }
          end
        end

        def card_inner(item)
          tag.div(class: "flex items-center gap-3") do
            safe_join(
              [
                plugin_icon(image_url: item.image_url, alt: item.name, size: :md),
                tag.span(item.name)
              ]
            )
          end
        end

        def card_attributes(item)
          attributes = { clickable: true, href: item.href, hover: :subtle }
          attributes[:target] = "_blank" if item.external
          attributes
        end
      end
    end
  end
end
