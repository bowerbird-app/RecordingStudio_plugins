RecordingStudioPlugins install complete.

Next steps:

1. Review config/initializers/recording_studio_plugins.rb.
2. Mount the engine. The generator adds the route at the configured mount path.
3. Register plugins from the host or from another gem's `to_prepare` block.
   For ChatGPT and Grok Bot, call `RecordingStudioPlugins.register_mcp_client(:chatgpt)`
   (and `:grok_bot`) in the initializer. Staff set `plugin_key` on the Oauth app.
4. Give people access to a workspace. The directory checks `authorized?` for `:view`, and action links check `:edit`. Root plugins stay admin-only. Inbound MCP clients are visible to everyone with view access.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
