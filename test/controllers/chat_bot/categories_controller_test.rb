require './test/test_helper'

module ChatBot
  class CategoriesControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes

      @category = Category.new name: 'Introduction'
      @sub_category = SubCategory.new name: 'Application Intro',
        category: @category,
        description: Faker::Lorem.sentence

      @category_2 = Category.new name: 'Usage'
      @sub_category_21 = SubCategory.new name: 'Application usage',
        category: @category_2,
        description: Faker::Lorem.sentence
      @sub_category_22 = SubCategory.new name: 'Registeration',
        category: @category_2,
        description: Faker::Lorem.sentence
    end

    def test_index
      get :index
      assert_response :success
    end

    def test_create
      total_categories = Category.count
      post :create, category: { name: 'Introduction' }
      assert_response :success

      assert_equal Category.count, total_categories + 1
    end
  end
end
