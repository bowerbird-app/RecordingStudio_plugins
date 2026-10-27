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
      follow_up = Dir.glob(File.join(dir, "db/migrate", "*_nonunique_recording_studio_plugin_appearance_plugin_key.rb"))

      assert_equal 1, first.size
      assert_equal 1, follow_up.size
      assert_includes File.read(first.first), "create_table :recording_studio_plugin_appearances"
      copied = File.read(first.first)
      assert_includes copied, "add_index :recording_studio_plugin_appearances, :plugin_key"
      refute_includes copied, "unique: true"
      assert_includes File.read(follow_up.first), "remove_index :recording_studio_plugin_appearances, :plugin_key"

      generator.stub(:say, nil) { generator.copy_migrations }
      second = Dir.glob(File.join(dir, "db/migrate", "*_create_recording_studio_plugin_appearances.rb"))
      second_follow_up = Dir.glob(
        File.join(dir, "db/migrate", "*_nonunique_recording_studio_plugin_appearance_plugin_key.rb")
      )

      assert_equal 1, second.size
      assert_equal 1, second_follow_up.size
    end
  end
end
