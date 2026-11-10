# frozen_string_literal: true

# collapse: :preserve is unused here. The widget is span 12, a full row of cards.
# Dashboard keeps a row action only when prepare marks the list truncated.
RecordingStudioDashboard.register(:plugins) do
  row :installable_plugins,
      title: RecordingStudioPlugins::Dashboard::InstallablePlugins.row_title,
      action: {
        label: RecordingStudioPlugins::Dashboard::InstallablePlugins.show_more_label,
        url: RecordingStudioPlugins::Dashboard::InstallablePlugins.directory_href
      } do
    widget :installable_plugins, span: 12
  end
end
