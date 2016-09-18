require 'test_helper'

module ChatBot
  class CategoryTest < ActiveSupport::TestCase
    test 'should not save without name' do
      category = Category.new
      assert_not category.save
    end
  end
end
