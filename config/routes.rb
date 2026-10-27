# frozen_string_literal: true

RecordingStudioPlugins::Engine.routes.draw do
  namespace :admin do
    get "plugins", to: "appearances#index", as: :plugins
    get "plugins/:key/edit", to: "appearances#edit", as: :plugin_edit,
                             constraints: { key: /[a-z][a-z0-9_]*/ }
    patch "plugins/:key", to: "appearances#update", as: :plugin,
                          constraints: { key: /[a-z][a-z0-9_]*/ }
    delete "plugins/:key/image", to: "appearances#destroy_image", as: :plugin_image,
                                 constraints: { key: /[a-z][a-z0-9_]*/ }
  end

  root "plugins#index"
  get ":key/people", to: "plugins#people", as: :plugin_people, constraints: { key: /[a-z][a-z0-9_]*/ }
end
