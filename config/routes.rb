# frozen_string_literal: true

RecordingStudioPlugins::Engine.routes.draw do
  namespace :admin do
    get "plugins", to: "appearances#index", as: :plugins
    patch "plugins", to: "appearances#update"
    delete "plugins/:key/image", to: "appearances#destroy_image", as: :plugin_image,
                                 constraints: { key: /[a-z][a-z0-9_]*/ }
  end

  root "plugins#index"
  get ":key/people", to: "plugins#people", as: :plugin_people, constraints: { key: /[a-z][a-z0-9_]*/ }
  get ":key", to: "plugins#show", as: :plugin, constraints: { key: /[a-z][a-z0-9_]*/ }
end
