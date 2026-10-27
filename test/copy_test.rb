# frozen_string_literal: true

require "test_helper"

class CopyTest < Minitest::Test
  include RecordingStudioPlugins::Copy

  def test_plugin_copy_keeps_a_real_apostrophe_and_marks_html_safe
    text = plugin_copy("directory.description")

    assert_equal "See what you can connect, and what's already set up.", text
    assert_predicate text, :html_safe?
    refute_includes text, "&#39;"
  end

  def test_people_copy_keeps_real_apostrophes
    assert_equal "Who's connected", plugin_copy("detail.people")
    assert_equal "Nobody's connected through here yet.", plugin_copy("detail.people_empty")
    assert_predicate plugin_copy("detail.people"), :html_safe?
  end
end
