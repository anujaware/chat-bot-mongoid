require './test/test_helper'

module ChatBot
  class ConversationTest < ActiveSupport::TestCase

    should validate_presence_of(:sub_category)
    should validate_presence_of(:dialog)
    should validate_numericality_of(:viewed_count).only_integer.is_greater_than(-1)

    describe 'Validation' do

      context 'conversation should' do
        before do
          @category = Category.new name: 'Introduction'
          @sub_category = SubCategory.new name: 'Application Intro',
                                          category: @category,
                                          description: Faker::Lorem.sentence
        end

        it 'not be saved if sub category is already exists under a scope of created_for'
        # create a conversation with a sub category by assigning a created for with a dummmy model
        # create a conversation with same sub category by assigning same created for

      end

    end

  end
end
