# frozen_string_literal: true

require "test_helper"

class CopyTest < Minitest::Test
  HELPER_PATH = File.expand_path("../app/helpers/recording_studio_plugins/application_helper.rb", __dir__)

  def test_plugin_copy_is_the_main_helper_and_does_not_unescape_or_mark_html_safe
    helper_source = File.read(HELPER_PATH)
    app_dir = File.expand_path("../app", __dir__)
    lib_dir = File.expand_path("../lib", __dir__)
    require File.expand_path("../app/helpers/recording_studio_plugins/plugin_icons.rb", __dir__)
    require HELPER_PATH
    helper = Class.new { include RecordingStudioPlugins::ApplicationHelper }.new

    assert_equal "Who's connected to ChatGPT",
                 helper.plugin_copy("detail.people_title_html", plugin: "ChatGPT")
    refute_includes helper_source, "html_safe"
    refute_includes helper_source, "unescapeHTML"
    refute File.exist?(File.expand_path("../lib/recording_studio_plugins/copy.rb", __dir__))
    Dir.glob("#{app_dir}/**/*.{rb,erb}").each do |path|
      refute_includes File.read(path), "html_safe", "#{path} must not call html_safe"
      refute_includes File.read(path), ".raw(", "#{path} must not call raw"
    end
    Dir.glob("#{lib_dir}/**/*.rb").each do |path|
      refute_includes File.read(path), "html_safe", "#{path} must not call html_safe"
      refute_includes File.read(path), "CGI.unescapeHTML", "#{path} must not unescape HTML"
    end
  end
end
