# frozen_string_literal: true

module RecordingStudioPlugins
  class InboundPeople
    def self.connections(**)
      RecordingStudioOauth.inbound_connections(**)
    end

    def self.labeled(plugin_key:, plugin_context:)
      new(
        connections(
          plugin_key: plugin_key,
          root: plugin_context.root_recording,
          actor: plugin_context.actor
        )
      ).labeled
    end

    def self.actor_class_for(type)
      klass = type.to_s.safe_constantize
      klass if klass.is_a?(Class) && klass < ActiveRecord::Base
    end

    def initialize(rows)
      @rows = Array(rows)
    end

    def labeled
      records = records_by_type
      label = RecordingStudioPlugins.configuration.actor_label
      @rows.map { |row| labeled_row(row, records, label) }
    end

    private

    def labeled_row(row, records, label)
      actor = records.dig(row[:actor_type].to_s, row[:actor_id].to_s)
      row.merge(name: label.call(actor))
    end

    def records_by_type
      @rows.group_by { |row| row[:actor_type].to_s }.each_with_object({}) do |(type, group), hash|
        records = records_for(type, group.map { |row| row[:actor_id] })
        hash[type] = records if records
      end
    end

    def records_for(type, ids)
      klass = self.class.actor_class_for(type)
      return unless klass.respond_to?(:where)

      klass.where(id: ids).to_a.index_by { |record| record.id.to_s }
    end
  end
end
