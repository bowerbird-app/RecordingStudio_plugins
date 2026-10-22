# frozen_string_literal: true

require "test_helper"

class SafeUrlTest < Minitest::Test
  def test_allows_https_and_a_single_slash_path
    assert_equal "https://example.com/docs", RecordingStudioPlugins::SafeUrl.allowed("https://example.com/docs")
    assert_equal "/plugins/dropbox", RecordingStudioPlugins::SafeUrl.allowed("/plugins/dropbox")
    assert RecordingStudioPlugins::SafeUrl.external?("https://example.com/docs")
    refute RecordingStudioPlugins::SafeUrl.external?("/plugins/dropbox")
  end

  def test_rejects_unsafe_urls
    [
      "http://example.com",
      "HTTP://example.com",
      "//example.com",
      "javascript:alert(1)",
      "data:text/html,hi",
      "https://user:pass@example.com/docs",
      "https://user@example.com/docs"
    ].each do |url|
      assert_nil RecordingStudioPlugins::SafeUrl.allowed(url), url
    end
  end
end
