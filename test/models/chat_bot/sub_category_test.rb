require './test/test_helper'

module ChatBot
  class SubCategoryTest < ActiveSupport::TestCase
    def setup
      @sub_category = SubCategory.new
    end

    def test_validate_name
      category = Category.new name: 'Introduction'
      @sub_category.category = category

      assert_not @sub_category.save, 'Name is blank/nil'

      @sub_category.name = 'Application Intro'
      assert @sub_category.save

      sub_category = SubCategory.new category: category, name: 'Application Intro'
      assert_not sub_category.save, 'Name is duplicate'

      sub_category = SubCategory.new category: category, name: 'application intro'
      assert_not sub_category.save, 'Name is duplicate (incase-sensitive)'

      sub_category = SubCategory.new category: category, name: "application  \t \n intro  \n"
      assert_not sub_category.save, 'Name is duplicate (after squish)'
      
      usage_category = Category.new name: 'Application Usage'
      sub_category = SubCategory.new category: usage_category, name: 'Application Intro'
      assert sub_category.save, 'Same sub category under two different categories.'
    end

    def test_category_validation
      @sub_category.name = 'Introduction'
      assert_not @sub_category.save, 'Category is nil'
    end
  end
end
