# frozen_string_literal: true

require_relative "lib/recording_studio_plugins/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_plugins"
  spec.version     = RecordingStudioPlugins::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_plugins"
  spec.summary     = "A directory of integrations for Recording Studio"
  spec.description = "Gems and host apps register plugins. People browse them, read how to connect " \
                     "and use each one, and see a status the owning gem reports."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_plugins"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_plugins/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "flat_pack", ">= 0.1.315"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", ">= 6.1.0"
  spec.add_dependency "recording_studio_accessible", ">= 0.18"
  spec.add_dependency "recording_studio_admin", ">= 2.5.1", "< 2.6"
  spec.add_dependency "recording_studio_attachable", ">= 0.22.0"
  spec.add_dependency "recording_studio_oauth", ">= 0.19.0"
end
