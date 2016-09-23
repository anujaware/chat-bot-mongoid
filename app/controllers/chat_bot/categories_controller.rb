require_dependency "chat_bot/application_controller"

module ChatBot
  class CategoriesController < ApplicationController

    def index
      @categories = Category.all
    end

    def create
      @category = Category.new safe_params

      respond_to do |format|
        if @category.save
          format.js {}
        else
          format.html { render action: 'new' }
          format.json { render action: :create, json: @category.errors, status: :unprocessable_entity }
          # added:
          format.js {}
        end
      end
    end

    def safe_params
      params.require(:category).permit(:name)
    end

  end
end
