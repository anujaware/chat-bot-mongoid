require './test/test_helper'

module ChatBot
  class CategoryTest < ActiveSupport::TestCase
    def setup
      @category = Category.new
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
  end
end
