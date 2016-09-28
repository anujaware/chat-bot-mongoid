require './test/test_helper'

module ChatBot
  class ConversationTest < ActiveSupport::TestCase

    should validate_presence_of(:sub_category)
    should validate_presence_of(:dialog)
    should validate_numericality_of(:viewed_count).only_integer.is_greater_than(-1)

    describe 'Conversation' do

      before do
        @category = Category.new name: 'Introduction'
        @sub_category = SubCategory.new name: 'Application Intro',
          category: @category,
          description: Faker::Lorem.sentence
        @dialog = Dialog.create code: 'T410',
          message: Faker::Lorem.sentence, sub_category: @sub_category

        @sub_category.update_attribute(:initial_dialog, @dialog)
        assert_equal @sub_category.reload.initial_dialog, @dialog

        class User
          include Mongoid::Document

          has_many :conversations, class_name: 'ChatBot::Conversation', as: :created_for
        end
        @user = User.create()
      end

      context 'Validation' do
        context 'conversation should' do
          it 'not be saved if sub category is already exists under a scope of created_for' do

            @conv_1 = Conversation.new(sub_category: @sub_category, created_for: @user)
            assert @conv_1.save
            @conv_2 = Conversation.new(sub_category: @sub_category, created_for: @user)
            assert !@conv_2.save
          end

        end
      end

      context 'Callbacks' do
        it 'should set dialog to initial dialog on create' do
          @conv_1 = Conversation.new(sub_category: @sub_category, created_for: @user)
          assert @conv_1.save
          assert @conv_1.dialog.present?
        end
      end

    end

  end
end
