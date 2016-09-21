Rails.application.routes.draw do

  mount ChatBot::Engine => "/chat_bot"

  root to: 'categories#index'
end
