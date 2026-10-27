# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_plugins/migrations/migrations_generator"

class MigrationsGeneratorTest < Minitest::Test
  def test_copy_migrations_is_idempotent
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "db/migrate"))
      generator = RecordingStudioPlugins::Generators::MigrationsGenerator.new(
        [],
        { skip_existing: true },
        destination_root: dir
      )

      generator.stub(:say, nil) { generator.copy_migrations }
      first = Dir.glob(File.join(dir, "db/migrate", "*_create_recording_studio_plugin_appearances.rb"))

      assert_equal 1, first.size
      assert_includes File.read(first.first), "create_table :recording_studio_plugin_appearances"
      assert_includes File.read(first.first), "add_index :recording_studio_plugin_appearances, :plugin_key, unique: true"

      generator.stub(:say, nil) { generator.copy_migrations }
      second = Dir.glob(File.join(dir, "db/migrate", "*_create_recording_studio_plugin_appearances.rb"))

      assert_equal 1, second.size
    end
  end
end
