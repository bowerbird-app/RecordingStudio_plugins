# frozen_string_literal: true

module RecordingStudioPlugins
  module AdminAppearanceConfig
    def admin_root_types
      Array(@admin_root_types).map(&:to_s)
    end

    def admin_root_types=(types)
      @admin_root_types = Array(types).map(&:to_s)
    end

    def admin_root_name
      @admin_root_name
    end

    def admin_root_name=(name)
      @admin_root_name = name.presence
    end

    def admin_recording_resolver
      @admin_recording_resolver || default_admin_recording_resolver
    end

    def admin_recording_resolver=(resolver)
      @admin_recording_resolver = resolver
    end

    private

    def default_admin_recording_resolver
      lambda do
        root = find_configured_admin_root
        next unless root

        RecordingStudio::Recording.where(
          RecordingStudio::Recording.recording_studio_trashable_kept_sql
        ).find_by(recordable: root)
      end
    end

    def find_configured_admin_root
      type_name = admin_root_types.first
      return if type_name.blank? || admin_root_name.blank?

      klass = type_name.safe_constantize
      return unless klass.respond_to?(:find_by)

      klass.find_by(name: admin_root_name)
    end
  end
end
