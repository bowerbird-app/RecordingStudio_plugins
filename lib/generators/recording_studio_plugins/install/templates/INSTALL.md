RecordingStudioPlugins install complete.

Next steps:

1. Review config/initializers/recording_studio_plugins.rb.
2. Mount the engine. The generator adds the route at the configured mount path.
3. Register plugins from the host or from another gem's `to_prepare` block.
4. Give people access to a workspace. The directory checks `authorized?` for `:view`, and action links check `:edit`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
