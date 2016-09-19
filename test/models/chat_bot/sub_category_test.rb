require './test/test_helper'

module ChatBot
  class SubCategoryTest < ActiveSupport::TestCase
    def setup
      @category = Category.new name: 'Introduction'
      @sub_category = SubCategory.new name: 'Application Intro',
        category: @category,
        description: Faker::Lorem.sentence
    end

    def test_validate_name
      assert @sub_category.save

      sub_category = SubCategory.new category: @category, name: 'Application Intro'
      assert_not sub_category.save, 'Name is duplicate'

      sub_category = SubCategory.new category: @category, name: 'application intro'
      assert_not sub_category.save, 'Name is duplicate (incase-sensitive)'

      sub_category = SubCategory.new category: @category, name: "application  \t \n intro  \n"
      assert_not sub_category.save, 'Name is duplicate (after squish)'
      
      usage_category = Category.new name: 'Application Usage'
      sub_category = SubCategory.new category: usage_category,
        name: 'Application Intro',
        description: Faker::Lorem.sentence
      assert sub_category.save, 'Same sub category under two different categories.'

      @sub_category.name = ''
      assert_not @sub_category.save, 'Name is blank/nil'
    end

    def test_category_validation
      @sub_category.category = nil
      assert_not @sub_category.save, 'Category is nil'
    end

    def test_validate_repeat_limit
      assert_equal @sub_category.repeat_limit, 0

      @sub_category.repeat_limit = 'abcd'
      assert_not @sub_category.save

      @sub_category.repeat_limit = '12.5'
      assert_equal @sub_category.repeat_limit, 12

      @sub_category.repeat_limit = -12
      assert_not @sub_category.save
    end

    def test_validate_description
      @sub_category.description = ''
      assert_not @sub_category.save
    end
  end
end
