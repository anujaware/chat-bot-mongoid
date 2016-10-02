require './test/test_helper'

module ChatBot
  class ConversationTest < ActiveSupport::TestCase

    should validate_presence_of(:sub_category)
    should validate_presence_of(:dialog)
    should validate_numericality_of(:viewed_count).only_integer.is_greater_than(-1)

    describe 'Conversation' do

      def create_dialog
        @category = Category.find_or_create_by name: Faker::Lorem.words(2)
        @sub_category = SubCategory.new name: Faker::Lorem.words(2),
          category: @category,
          description: Faker::Lorem.sentence
        @dialog = Dialog.create code: 'T410',
          message: Faker::Lorem.sentence, sub_category: @sub_category

        @sub_category.dialogs << @dialog
        @sub_category.update_attribute(:initial_dialog, @dialog)
        assert_equal @sub_category.reload.initial_dialog, @dialog
        @sub_category
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
          context '#set_default on create' do
            it 'should set dialog to initial dialog on' do
              @conv_1 = Conversation.create(sub_category: @sub_category, created_for: @user)
              assert @conv_1.save
              assert @conv_1.dialog.present?
            end

            it 'should set priority' do
              @conv_1 = Conversation.create(sub_category: @sub_category,
                                            created_for: @user,
                                            priority: 6)
              assert @conv_1.save
              assert_equal @conv_1.priority, 6
            end
          end
        end
      end

      describe 'Methods' do
        context '#schedule should' do
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

      it 'increased viewed count at some point'

      describe 'After finish i.e. state changed to "finished"' do
        it 'should "finished" if decision is empty and interval is also empty' do
        end


        before do
          @sub_cat_1, @sub_cat_2, @sub_cat_3 = 3.times.collect do |num|
            create_dialog
          end

          @sub_cat_1.update_attributes({priority: 3, starts_on_key: SubCategory::AFTER_DAYS,
                                        starts_on_val: 2, is_ready_to_schedule: true})
          @sub_cat_2.update_attributes({priority: 3, starts_on_key: SubCategory::AFTER_DAYS,
                                        starts_on_val: 3, is_ready_to_schedule: true})
          @sub_cat_3.update_attributes({priority: 3, starts_on_key: SubCategory::IMMEDIATE,
                                        is_ready_to_schedule: true})

          @d1 = @sub_cat_1.initial_dialog
          @d2 = Dialog.create message: Faker::Lorem.sentence, sub_category: @sub_cat_1
          @sub_cat_1.dialogs << @d2
          @sub_cat_1.save
          @d2.options = [Option.create({name: Faker::Lorem.word, interval: 'DAY:5'})]
          @d1.options.create({name: Faker::Lorem.word, decision: @d2})

          class User
            include Mongoid::Document

            has_many :conversations, class_name: 'ChatBot::Conversation', as: :created_for
          end
          @user = User.create()

          Conversation.schedule(@user)
          response = Conversation.fetch(@user)
          @conv_1 = @user.conversations.find_by(sub_category: @sub_cat_1)
          assert_equal response, {conv_id: @conv_1.id,
                                  dialog_data: @d1.reload.data_attributes}
          assert @conv_1.started?

          selected_option = @d1.options.first
          response = Conversation.fetch(@user, selected_option.id)
          assert_equal @conv_1.reload.option, selected_option
        end

        it 'reschedule after 5 days as interval is DAY:5'
        # Create a conversation with two dialogs
        # Last dialog with option inverval set to DAY:5 and decision set to nil
        # Go through the conversation
        # Check -> Scheduled date should set, dialog set to initial dialog, should be in released state

        it 'next time conversation should start from 2nd dialog'
        # Create a conversation with three dialogs -> T1, T2, T3
        # Last dialog with option inverval set to DAY:3 and decision set to T2
        # Go through the conversation
        # Check -> Scheduled date should set, dialog set to T2, should be in released state

        it 'do not reschedule if crossed repeat limit'
        # Create conversation metadata i.e.sub category with repeat limit 3
        # Create two dialogs last one having interval DAY:3
        # Create conversation object and set its viewed count to 3
        # Go through conversation
        # Check after finish -> State changed to 'finished'

        it 'create dependant i.e. after_dialog coversation if not created'
        # Create a two metadata conversation
        #   1. Create a conversation with two dialogs -> T1, T2
        #   2. T2 -> interval DAY:3
        #   3. Create another sub category with starts on = after_dialog T2
        # Check only one conversation should exists for a user
        # Go though first conversation
        # After finish first conversation
        # Check -> another conversation has been created
      end

      describe 'fetch next conversation with the crieteria' do
        # Create three conversations with different priority
        # state released, scheduled date less than or equal to today
        context 'positive' do
          it 'should return started conversations'
          # Call next fetch next conversation multiple times which should always return higher priority conversation
          it 'released'
          # mark one of them higher priority conversation as not released
          # fetch conversation should skip scheduled conversation
          it 'scheduled at less than or equal to today'
          # Set schedule date to future date to two conversation with higher priority
          # Fetch conv should return
          it 'sort by priority'
          it 'sort by scheduled date'
          it 'sort by viewed count'
        end
        context 'negative' do
          it 'should return return started conversations even if released conversation exists with high priority'
          it 'not return released conversation with date greater than today'
        end
      end
    end
  end
end
