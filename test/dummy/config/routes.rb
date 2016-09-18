Rails.application.routes.draw do

  mount ChatBot::Engine => "/chat_bot"
end
