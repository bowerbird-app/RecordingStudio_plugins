# frozen_string_literal: true

require "test_helper"

class CopyTest < Minitest::Test
  def test_plugin_copy_is_the_main_helper_and_does_not_unescape_or_mark_html_safe
    helper = File.read(File.expand_path("../app/helpers/recording_studio_plugins/application_helper.rb", __dir__))
    app_dir = File.expand_path("../app", __dir__)
    lib_dir = File.expand_path("../lib", __dir__)

    assert_includes helper, "def plugin_copy(key, default: nil)"
    assert_includes helper, 'RecordingStudio.t("recording_studio.plugins.#{key}", default: default)'
    refute_includes helper, "html_safe"
    refute_includes helper, "unescapeHTML"
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
