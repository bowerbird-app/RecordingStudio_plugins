RecordingStudioPlugins install complete.

Next steps:

1. Review config/initializers/recording_studio_plugins.rb.
2. Mount the engine. The generator adds the route at the configured mount path.
3. Register plugins from the host or from another gem's `to_prepare` block.
4. Give people access to a workspace. The directory checks `authorized?` for `:view`. Action links on registered plugins check `:edit`. Root plugins from Oauth are listed only for workspace admins (`:admin`).
5. Set `config.enabled_plugins` to the Oauth provider keys this host should list (default is none). Register those providers with Oauth from the provider gem, or they will not appear.
6. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
