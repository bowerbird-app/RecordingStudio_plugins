RecordingStudioPlugins install complete.

Next steps:

1. Review config/initializers/recording_studio_plugins.rb.
2. Mount the engine. The generator adds the route at the configured mount path.
3. Install migrations with `bin/rails generate recording_studio_plugins:migrations`, then `bin/rails db:migrate`.
   The install generator also runs the migrations generator. Skip copies that already exist.
4. Add `RecordingStudioPlugins::PluginAppearance` to host `recordable_types`. Enable the `:plugins`
   admin section on the admin root. Mount Admin (`recording_studio_admin_for`) and Attachable.
   Grant Accessible access on the admin root to site staff only.
5. Register plugins from the host or from another gem's `to_prepare` block.
   For ChatGPT and Grok Bot, call `RecordingStudioPlugins.register_mcp_client(:chatgpt)`
   (and `:grok_bot`) in the initializer. Staff set `plugin_key` on the Oauth app.
6. Give people access to a workspace. The directory checks `authorized?` for `:view`, and action links check `:edit`. Root plugins stay admin-only. Inbound MCP clients are visible to everyone with view access.
7. Set `config.enabled_plugins` to the Oauth provider keys this host should list (default is none).
8. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
