require_dependency "chat_bot/application_controller"

module ChatBot
  class CategoriesController < ApplicationController

    def index
      @categories = Category.all
    end

  end
end
