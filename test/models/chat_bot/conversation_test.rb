require './test/test_helper'

module ChatBot
  class ConversationTest < ActiveSupport::TestCase

    should validate_presence_of(:sub_category)
    should validate_presence_of(:dialog)
    should validate_numericality_of(:viewed_count).only_integer.is_greater_than(-1)

    describe 'Conversation' do

      def create_dialog
        @category = Category.new name: 'Introduction'
        @sub_category = SubCategory.new name: 'Application Intro',
          category: @category,
          description: Faker::Lorem.sentence
        @dialog = Dialog.create code: 'T410',
          message: Faker::Lorem.sentence, sub_category: @sub_category

        @sub_category.update_attribute(:initial_dialog, @dialog)
        assert_equal @sub_category.reload.initial_dialog, @dialog
      end

      after do
        DatabaseCleaner.clean
      end

      describe '' do
        before do
          create_dialog
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

      describe 'Methods' do
        context '#shedule should' do
          before do
            create_dialog
            class User
              include Mongoid::Document

              has_many :conversations, class_name: 'ChatBot::Conversation', as: :created_for
            end
            @user = User.create()
            @sub_cat_dialog, @sub_cat_days, @sub_cat_imm = {
              'after_dialog' => @dialog.code,
              'after_days' => 4,
              'immediate' => nil }.collect do |key, val|
                sub_category = SubCategory.new name: Faker::Lorem.words(2),
                  category: @category,
                  description: Faker::Lorem.sentence,
                  starts_on_key: key,
                  starts_on_val: val,
                  is_ready_to_schedule: true

                dialog = Dialog.create message: Faker::Lorem.sentence, sub_category: sub_category

                sub_category.update_attribute(:initial_dialog, dialog)
                sub_category
              end

              assert_equal SubCategory.count, 4
              Conversation.schedule(@user)
              Conversation.all.each do |conv|
                assert conv.released?
              end
          end

          context 'create conversations' do
            it 'which are marked as ready to scheduled' do
              assert (SubCategory.count > SubCategory.ready.count)
              assert_equal @user.conversations.count, 2
            end

            context 'and assign appropriate scheduled date to' do
              it 'current date for immediate' do
                assert_equal @sub_cat_imm.starts_on_val, nil
                conv = Conversation.find_by(sub_category_id: @sub_cat_imm.id)
                assert_equal conv.scheduled_at, Date.current
              end

              it '4th day from current date' do
                assert_equal @sub_cat_days.starts_on_val.to_i, 4
                conv = Conversation.find_by(sub_category: @sub_cat_days)
                assert_equal conv.scheduled_at, Date.current + 4.days
              end
            end

            it 'and do not release it if approval required' do
              sub_category = SubCategory.new name: Faker::Lorem.words(2),
                category: @category,
                description: Faker::Lorem.sentence,
                is_ready_to_schedule: true,
                approval_require: true

              dialog = Dialog.create message: Faker::Lorem.sentence, sub_category: sub_category

              #sub_category.update_attribute(:initial_dialog, dialog)
              Conversation.schedule(@user)
              assert Conversation.find_by(aasm_state: 'scheduled').present?
            end
          end

          context 'not create conversations' do

            it 'whose starts_on_key is after_dialog' do
              assert @sub_cat_dialog.present?
              conv = Conversation.where(sub_category: @sub_cat_dialog)
              assert !conv.present?
              count = SubCategory.ready.count
              assert_equal @user.conversations.count, count - 1
            end

            it 'if already created' do
              sub_category = SubCategory.new name: Faker::Lorem.words(2),
                category: @category,
                description: Faker::Lorem.sentence,
                is_ready_to_schedule: true

              dialog = Dialog.create message: Faker::Lorem.sentence, sub_category: sub_category

              sub_category.update_attribute(:initial_dialog, dialog)
              conv_count = Conversation.count
              Conversation.schedule(@user)
              conv = Conversation.where(sub_category: sub_category).first
              assert conv.present?
              assert (conv_count == (Conversation.count - 1))
            end

          end
        end
      end
    end
  end
end
