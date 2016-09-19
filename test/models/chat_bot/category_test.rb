require './test/test_helper'

module ChatBot
  class CategoryTest < ActiveSupport::TestCase
    should validate_presence_of :name

    def setup
      @category = Category.new #categories(:one)
    end

    def test_save_fail_without_name
      assert_not @category.save, "Name blank/nil"
    end

    def test_save_fail_for_duplicate_name
      @category.name = 'Cat 1'
      assert @category.save
      category = Category.new name: 'Cat 1' #categories(:two)
      assert_not category.save
    end

    def test_save_fail_for_incase_sensitive_duplicate_name
      category = Category.new name: 'Cat 1'
      assert category.save
      category = Category.new name: 'cat 1'
      assert_not category.save
    end
    
    def test_strip_name
      category = Category.new name: "   Cat   \n \t 1  \n "
      assert category.save
      category.reload
      assert_equal category.name, 'Cat 1'
    end

    def test_sub_categories
      #assert_must Category, have_many(:sub_categories)
=begin
### TODO: ERROR - Testing association
ChatBot::CategoryTest#test_sub_categories:
NoMethodError: undefined method `matches?' for ChatBot::Category:Class
    test/models/chat_bot/category_test.rb:35:in `test_sub_categories'
=end
    end
  end
end
