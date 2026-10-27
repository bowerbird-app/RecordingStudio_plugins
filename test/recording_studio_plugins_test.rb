# frozen_string_literal: true

require "test_helper"

class RecordingStudioPluginsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.7.0", ::RecordingStudioPlugins::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPlugins::Engine
  end

  def test_gemspec_pins_recording_studio_6_1
    gemspec = File.read(File.expand_path("../recording_studio_plugins.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", ">= 6.1.0"'
    assert_includes gemspec, 'spec.add_dependency "flat_pack", ">= 0.1.315"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", ">= 0.18"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_admin", ">= 2.5.1"'
    refute_includes gemspec, '"< 2.6"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_attachable", ">= 0.22.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_oauth", ">= 0.19.0"'
  end

  def test_gemspec_excludes_cursor_config
    spec = Gem::Specification.load(File.expand_path("../recording_studio_plugins.gemspec", __dir__))
    cursor_files = spec.files.select { |path| path == ".cursor" || path.split("/").include?(".cursor") }

    assert_empty cursor_files, "gemspec must not package .cursor/ (got #{cursor_files.inspect})"
  end

  def test_cursor_environment_is_repo_managed_without_snapshot
    path = File.expand_path("../.cursor/environment.json", __dir__)
    json = JSON.parse(File.read(path))

    assert_equal "recording-studio-gem-template", json["name"]
    assert_equal ".cursor/install.sh", json["install"]
    assert_equal ".cursor/start.sh", json["start"]
    refute json.key?("snapshot"), "snapshot pins a Personal build and skips install"
    refute json.key?("agentCanUpdateSnapshot")
  end

  def test_cursor_install_still_fetches_skills
    install_script = File.read(File.expand_path("../.cursor/install.sh", __dir__))

    assert_includes install_script, "fetch-skills.sh"
  end

  def test_dummy_gemfile_pins_verified_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, "widen_recording_studio_requirement"
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v6.1.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.22.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_Oauth", tag: "v0.19.0"'
    refute_includes gemfile, "TEMPORARY"
    refute_includes gemfile, "cursor/inbound-plugin-key-e105"
    refute_includes gemfile, 'tag: "v0.18.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "v2.5.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_api", tag: "v0.14.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.22.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_logs", tag: "v0.4.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_site_settings", tag: "v0.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.11.3", require: false'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.5.0"'
    refute_includes gemfile, 'RecordingStudio_accessible", tag: "v0.18.0"'
    refute_includes gemfile, 'RecordingStudio_metrics", tag: "v0.6.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.8.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_cache", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.320"'
    refute_includes gemfile, 'tag: "v0.1.213"'
    refute_includes gemfile, 'tag: "v4.7.0"'
    refute_includes gemfile, "recording_studio/v3.0.0"
  end

  def test_dummy_schema_includes_accessible_depends_on_recording_id
    schema = File.read(File.expand_path("dummy/db/schema.rb", __dir__))
    migration = File.read(
      File.expand_path(
        "dummy/db/migrate/20260911024811_add_depends_on_recording_id_to_recording_studio_accesses.rb",
        __dir__
      )
    )

    assert_includes schema, 't.uuid "depends_on_recording_id"'
    assert_includes schema, "index_recording_studio_accesses_on_depends_on_recording_id"
    assert_includes migration, "add_column :recording_studio_accesses, :depends_on_recording_id, :uuid"
    assert_includes schema, 'create_table "recording_studio_access_invitations"'
    assert_includes schema, "idx_rs_access_invitations_token_digest"
    invitation_migration = File.read(
      File.expand_path(
        "dummy/db/migrate/20261001000011_create_recording_studio_access_invitations.rb",
        __dir__
      )
    )
    assert_includes invitation_migration, "create_table :recording_studio_access_invitations"
    assert_includes schema, 't.string "role", default: "view", null: false'
    refute_includes schema, 't.integer "role", default: 0, null: false'
    role_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_change_recording_studio_accesses_role_to_string.rb", __dir__)
    ).max
    assert role_migration, "expected role-column migration in dummy db/migrate"
    assert_includes File.read(role_migration), "change_column :recording_studio_accesses, :role, :string"

    assert_includes schema, 't.string "plugin_key"'
    assert_includes schema, "index_recording_studio_oauth_clients_on_plugin_key"
    assert_includes schema, 'create_table "recording_studio_oauth_outbound_connections"'
    assert_includes schema, 'create_table "recording_studio_access_constraints"'
    assert_includes schema, 'create_table "recording_studio_access_rules"'
    assert_includes schema, "index_recording_studio_access_constraints_on_action"
    assert_includes schema, "index_recording_studio_access_rules_on_action"
    assert_includes schema, 'create_table "recording_studio_plugin_appearances"'
    appearance_index = 't.index ["plugin_key"], name: "index_recording_studio_plugin_appearances_on_plugin_key"'
    assert_includes schema, "#{appearance_index}, unique: true"
    assert_includes schema, 'create_table "admin_roots"'
    assert_includes schema, 'create_table "active_storage_blobs"'
    assert_includes schema, 'create_table "recording_studio_attachable_attachments"'
    constraint_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_create_recording_studio_access_constraints.rb", __dir__)
    ).max
    rule_migration = Dir.glob(
      File.expand_path("dummy/db/migrate/*_create_recording_studio_access_rules.rb", __dir__)
    ).max
    assert constraint_migration, "expected access constraints migration in dummy db/migrate"
    assert rule_migration, "expected access rules migration in dummy db/migrate"
    assert_includes File.read(constraint_migration), "create_table :recording_studio_access_constraints"
    assert_includes File.read(rule_migration), "create_table :recording_studio_access_rules"
  end

  def test_template_does_not_ship_copied_core_hooks_or_base_service
    refute File.exist?(File.expand_path("../lib/recording_studio_plugins/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_plugins/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_plugins/services/example_service.rb", __dir__))
  end

  def test_plugins_gem_does_not_ship_an_example_capability
    refute File.exist?(File.expand_path("../lib/recording_studio_plugins/capabilities/example.rb", __dir__))
    refute defined?(RecordingStudio::Capabilities::Example)
  end

  def test_engine_controllers_delegate_layout_and_do_not_hardcode_it
    controller = File.read(
      File.expand_path("../app/controllers/recording_studio_plugins/application_controller.rb", __dir__)
    )
    gem_root = File.expand_path("..", __dir__)
    index = File.read(File.expand_path("../app/views/recording_studio_plugins/plugins/index.html.erb", __dir__))
    routes = File.read(File.expand_path("../config/routes.rb", __dir__))

    assert_includes controller, "recording_studio_layout { RecordingStudioPlugins.configuration.layout }"
    refute_includes controller, "UsesDefaultLayout"
    refute_includes controller, 'layout "recording_studio/default_layout"'
    assert_empty RecordingStudio::Layout.hardcoded_layout_paths(gem_root)
    assert_includes index, "content_for :title"
    refute_includes index, "recording_studio_page_nav"
    refute_includes index, "FlatPack::PageTitle::Component"
    refute_includes routes, "plugins#show"
    refute File.exist?(File.expand_path("../app/views/recording_studio_plugins/plugins/show.html.erb", __dir__))
  end

  def test_dummy_app_uses_recording_studio_default_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)

    assert_includes controller_source, "recording_studio_layout { RecordingStudioPlugins.configuration.layout }"
    refute_includes controller_source, "UsesDefaultLayout"
    refute_includes controller_source, "recording_studio/default_layout"
    refute_includes controller_source, "flat_pack_sidebar"
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    refute File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
  end

  def test_dummy_blank_layout_uses_padded_page_layout_without_a_sidebar
    blank = File.read(File.expand_path("dummy/app/views/layouts/recording_studio/blank.html.erb", __dir__))
    default_layout = File.read(
      File.expand_path("dummy/app/views/layouts/recording_studio/default_layout.html.erb", __dir__)
    )
    initializer = File.read(File.expand_path("dummy/config/initializers/recording_studio_plugins.rb", __dir__))

    assert_includes blank, "FlatPack::PageLayout::Component.new(width: :default)"
    refute_includes blank, "width: :full"
    refute_includes blank, "SidebarLayout"
    assert_includes default_layout, "FlatPack::PageLayout::Component.new(width: :default)"
    assert_includes default_layout, "SidebarLayout"
    assert_includes initializer, 'next "recording_studio/blank" if controller.controller_path == ' \
                                 '"recording_studio_plugins/admin/appearances"'
  end

  def test_engine_plugin_views_use_layout_title_and_nav_not_page_padding
    gem_root = File.expand_path("..", __dir__)
    views = Dir[File.join(gem_root, "app/views/recording_studio_plugins/**/*.html.erb")]
    refute_empty views

    views.each do |view_path|
      source = File.read(view_path)

      refute_includes source, "PageLayout::Component"
      refute_includes source, "width: :full"
    end

    index = File.read(File.join(gem_root, "app/views/recording_studio_plugins/plugins/index.html.erb"))
    admin_index = File.read(File.join(gem_root, "app/views/recording_studio_plugins/admin/appearances/index.html.erb"))
    admin_edit = File.read(File.join(gem_root, "app/views/recording_studio_plugins/admin/appearances/edit.html.erb"))

    assert_includes index, "content_for :title"
    assert_includes index, "content_for :subtitle"
    refute_includes index, "flat_pack_page_nav"
    assert_includes admin_index, "content_for :title"
    assert_includes admin_index, "flat_pack_page_nav"
    assert_includes admin_edit, "content_for :title"
    assert_includes admin_edit, "flat_pack_page_nav"
    assert_includes admin_edit, "FlatPack::ImageInput::Component"
    refute_includes admin_edit, "cols: 2"
    refute_includes admin_edit, "PageLayout"
    assert_includes admin_edit, "flex w-full max-w-full items-start gap-4"
    assert_includes admin_edit, "min-w-0 flex-1"
    refute_includes admin_edit, "w-72"
    refute_includes admin_edit, "label: plugin_copy"
    assert_includes admin_edit, "mt-6 w-fit"
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, "dummy_document_attributes"
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/rich_text"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "../../../vendor/engines/flat_pack/app/components"
    assert_includes tailwind_source, "../../../vendor/engines/recording_studio/app/views"
    refute_includes tailwind_source, "vendor/bundle/**/flatpack/app/components"
    refute_includes tailwind_source, "recordingstudio-*"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"

    head_partial = File.read(
      File.expand_path("dummy/app/views/recording_studio/_default_layout_head.html.erb", __dir__)
    )
    assert_includes head_partial, 'stylesheet_link_tag "flat_pack/application"'

    rake_task = File.read(File.expand_path("dummy/lib/tasks/tailwindcss.rake", __dir__))
    assert_includes rake_task, "FlatPack::Engine.root"
    assert_includes rake_task, "RecordingStudio::Engine.root"
    assert_includes rake_task, "RecordingStudioAttachable::Engine.root"
    assert_includes rake_task, "RecordingStudioAdmin::Engine.root"
    assert_includes rake_task, "tailwindcss:link_engine_sources"
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, '"Workspace"'
    assert_includes initializer_source, '"Folder"'
    assert_includes initializer_source, '"Page"'
    assert_includes initializer_source, '"AdminRoot"'
    assert_includes initializer_source, "RecordingStudioPlugins::PluginAppearance"
    assert_includes initializer_source, "RecordingStudioAttachable::Attachment"
    refute_includes initializer_source, "RecordingStudioAttachable::Library"
    refute_includes initializer_source, "RecordingStudioAttachable::Placement"
    assert_includes initializer_source, "RecordingStudioSiteSettings::SiteSetting"
    assert_includes initializer_source, "RecordingStudioApi::AdminApi"
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"

    switch_page = File.read(
      File.expand_path("dummy/app/views/recording_studio_root_switchable/root_switches/show.html.erb", __dir__)
    )
    assert_includes switch_page, "with_close"
    refute_includes switch_page, "anchor_label:"
    refute_includes switch_page, "Card::Component.new(style:"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to validate the Recording Studio addon template"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "redirects to `/`"
    refute_includes readme_source, "flat_pack_sidebar"
    assert_includes readme_source, "Admin root at `/admin`"
    assert_includes readme_source, "test/dummy/db/seeds.rb"
    assert_includes readme_source, 'Switch to the "Admin" root'
    assert_includes readme_source, "PageLayout"
    assert_includes readme_source, "width: :default"
    refute_includes readme_source, "full-width"
  end

  def test_readme_covers_the_plugins_directory
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "RecordingStudioPlugins.register"
    assert_includes readme, "register_mcp_client"
    assert_includes readme, "available?"
    assert_includes readme, "RecordingStudioPlugins::Status"
    assert_includes readme, "RecordingStudioPlugins::Context"
    assert_includes readme, "hidden_keys"
    assert_includes readme, "enabled_plugins"
    assert_includes readme, "kind: :root"
    assert_includes readme, "kind: :user"
    assert_includes readme, "Plugin names and pictures"
    assert_includes readme, "recording_studio_admin_for"
    assert_includes readme, "inbound_connection_status"
    assert_includes readme, "McpClientStatus"
    assert_includes readme, "setup_url"
    assert_includes readme, "Oauth is a hard dependency"
    assert_includes readme, "v2.5.1"
    assert_includes readme, "v0.22.0"
    assert_includes readme, ">= 6.1.0"
    assert_includes readme, ">= 0.19.0"
    assert_includes readme, "recording_studio_layout"
    assert_includes readme, "Admin, API, Cache, Metrics, Site Settings, Trashable"
    assert_includes readme, "Recording Studio MCP"
    assert_includes readme, "to_prepare"
    assert_includes readme, "pattern, not shipped code"
    refute_includes readme, %w[Gem Template].join
    refute_includes readme, "WordPress"
    refute_includes readme, "Grokbot"
    refute_includes readme, "press kit"
    refute_includes readme, "v3 declarations"
    refute_includes readme, "RecordingStudio v3"
  end

  def test_dummy_home_page_uses_demo_title_only
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, 'title: "Template Demo"'
    assert_includes view_source, 'subtitle: "This dummy app is the browser-facing demo surface for the template."'
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "dummy_page_nav"
    refute_includes view_source, 'title: "Demo"'
    refute_includes view_source, "FlatPack::Breadcrumb::Component"
  end

  def test_dummy_docs_pages_use_minimal_flatpack_documentation_components
    docs_view_paths = Dir[File.expand_path("dummy/app/views/docs/*.html.erb", __dir__)].reject do |view_path|
      File.basename(view_path).start_with?("_")
    end
    refute_empty docs_view_paths

    docs_view_paths.each do |view_path|
      view_source = File.read(view_path)

      assert_includes view_source, "dummy_page_nav"
      refute_includes view_source, "FlatPack::PageTitle::Component"
      refute_includes view_source, "FlatPack::Card::Component"
      refute_includes view_source, "FlatPack::Breadcrumb::Component"
    end

    methods_view = File.read(File.expand_path("dummy/app/views/docs/methods.html.erb", __dir__))
    assert_includes methods_view, "FlatPack::SectionTitle::Component"
    assert_includes methods_view, "FlatPack::CodeBlock::Component"

    gem_views_view = File.read(File.expand_path("dummy/app/views/docs/gem_views.html.erb", __dir__))
    assert_includes gem_views_view, "FlatPack::Table::Component"
    refute_includes gem_views_view, "FlatPack::List::Component"

    recordable_types_view = File.read(File.expand_path("dummy/app/views/docs/recordable_types.html.erb", __dir__))
    assert_includes recordable_types_view, "FlatPack::List::Component"
    refute_includes recordable_types_view, "v3 parent/root"

    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_dummy_recordings_tree_view_omits_structure_section_copy
    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))

    assert_includes recordings_tree_view, 'title: "Recordings tree"'
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    recording_tree_partial = File.read(File.expand_path("dummy/app/views/docs/_recording_tree_node.html.erb", __dir__))
    assert_includes recording_tree_partial, "parent_builder.node"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_plugins/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end
end
