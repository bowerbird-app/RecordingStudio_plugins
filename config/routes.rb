# frozen_string_literal: true

RecordingStudioPlugins::Engine.routes.draw do
  root "plugins#index"
  get ":key/people", to: "plugins#people", as: :plugin_people, constraints: { key: /[a-z][a-z0-9_]*/ }
  get ":key", to: "plugins#show", as: :plugin, constraints: { key: /[a-z][a-z0-9_]*/ }
end
