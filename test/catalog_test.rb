# frozen_string_literal: true

require "test_helper"

class CatalogTest < Minitest::Test
  def setup
    RecordingStudioPlugins.clear!
  end

  def teardown
    RecordingStudioPlugins.clear!
  end

  def test_empty_states
    catalog = RecordingStudioPlugins::Catalog.new([])
    assert_equal :none, catalog.filter(query: "drive", category: "storage").empty

    listings = [listing(:google_drive, "Google Drive", "Import files", :storage)]
    catalog = RecordingStudioPlugins::Catalog.new(listings)

    assert_nil catalog.filter(query: "", category: nil).empty
    assert_equal :category, catalog.filter(query: "", category: "social").empty
    assert_equal :search, catalog.filter(query: "zzzz", category: nil).empty
    assert_equal :category, catalog.filter(query: "zzzz", category: "social").empty
    assert_equal [:google_drive], catalog.filter(query: "STORAGE", category: nil).listings.map(&:key)
  end

  private

  def listing(key, name, description, category)
    definition = RecordingStudioPlugins::Definition.new(
      key: key,
      name: name,
      description: description,
      category: category,
      icon: "cloud",
      provider: nil,
      position: 1,
      owner: "test"
    )
    plugin_context = RecordingStudioPlugins::Context.new(actor: nil, root_recording: nil)
    RecordingStudioPlugins::Listing.new(definition, plugin_context)
  end
end
