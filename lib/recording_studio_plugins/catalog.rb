# frozen_string_literal: true

module RecordingStudioPlugins
  class Catalog
    Result = Data.define(:listings, :empty)

    def initialize(listings)
      @listings = listings
    end

    def filter(query:, category:)
      return Result.new(listings: [], empty: :none) if @listings.empty?

      scoped = in_category(category)
      return Result.new(listings: [], empty: :category) if category.present? && scoped.empty?

      matched = search(scoped, query)
      return Result.new(listings: [], empty: :search) if query.to_s.strip.present? && matched.empty?

      Result.new(listings: matched, empty: nil)
    end

    private

    def in_category(category)
      return @listings if category.blank?

      @listings.select { |listing| listing.category.to_s == category.to_s }
    end

    def search(listings, query)
      needle = query.to_s.strip.downcase
      return listings if needle.empty?

      listings.select { |listing| listing.search_text.include?(needle) }
    end
  end
end
