require './test/test_helper'

module ChatBot
  class CategoryTest < ActiveSupport::TestCase
    def setup
      @category = Category.new
    end

    def test_name

    end

    def test_save_fail_without_name
      assert_not @category.save
    end
    
    def test_save_fail_for_duplicate_name
      @category.name = 'Cat1'
      assert_not @category.save
      category = categories(:two)
      assert_not category.save
    end
  end
end
