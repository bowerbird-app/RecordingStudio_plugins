# frozen_string_literal: true

# collapse: :preserve is unused here. The widget is span 12, a full row of cards.
RecordingStudioDashboard.register(:plugins) do
  row :installable_plugins, title: "Plugins you can connect" do
    widget :installable_plugins, span: 12
  end
end
