ChatBot::Engine.routes.draw do

  resources :categories, only: [:index]

  root to: 'categories#index'

end
