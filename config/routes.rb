ChatBot::Engine.routes.draw do

  resources :categories, only: [:index, :create]

  root to: 'categories#index'

end
