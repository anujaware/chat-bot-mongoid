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
        @dialog = Dialog.create message: Faker::Lorem.sentence, sub_category: @sub_category

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
              @sub_category.update_attribute(:priority, 6)
              @conv_1 = Conversation.create(sub_category: @sub_category,
                                            created_for: @user)
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

      describe 'After completing a conversations it should' do

        before do
          @sub_cat_1, @sub_cat_2, @sub_cat_3 = 3.times.collect do |num|
            create_dialog
          end

          @sub_cat_1.update_attributes({priority: 2, starts_on_key: SubCategory::AFTER_DAYS,
                                        starts_on_val: 2, is_ready_to_schedule: true, repeat_limit: 3})
          @sub_cat_2.update_attributes({priority: 3, starts_on_key: SubCategory::AFTER_DAYS,
                                        starts_on_val: 3, is_ready_to_schedule: true})
          @sub_cat_3.update_attributes({priority: 4, starts_on_key: SubCategory::IMMEDIATE,
                                        is_ready_to_schedule: true})

          @d1 = @sub_cat_1.initial_dialog
          @d2 = Dialog.create message: Faker::Lorem.sentence, sub_category: @sub_cat_1,
                options: {'0' => {name: Faker::Lorem.word, interval: 'DAY:5'}}
          @sub_cat_1.dialogs << @d2

          option = Option.create({name: Faker::Lorem.word, decision_id: @d2.id, dialog_id: @d1.id})

          @d1.options = [option]

          class User
            include Mongoid::Document

            has_many :conversations, class_name: 'ChatBot::Conversation', as: :created_for
          end
          @user = User.create()
          Conversation.schedule(@user)
          assert_equal @user.conversations.count, 3

          @conv_1 = @user.conversations.find_by(sub_category: @sub_cat_1)
          assert @conv_1.update_attributes(scheduled_at: Date.current - 1.day)
          assert_equal @conv_1.viewed_count, 0

          response = Conversation.fetch(@user)

          assert_equal @conv_1.priority, 2

          assert_equal response, {conv_id: @conv_1.id,
                                  dialog_data: @d1.reload.data_attributes}
          assert @conv_1.reload.started?

          @selected_option = @d1.options.last
          assert_equal @selected_option.decision, @d2

          response = Conversation.fetch(@user, @selected_option.id)
        end

        it '"finished" if decision is empty and interval is also empty' do
          option = @d2.options.first
          assert option.update_attribute(:interval, nil)
          response = Conversation.fetch(@user, option.id)
          @conv_1.finished?
        end

        it 'save next dialog' do
          assert_equal @conv_1.reload.dialog, @d2
        end

        it 'save selected option' do
          assert_equal @conv_1.reload.option, @selected_option
          option = @d2.options.first
          response = Conversation.fetch(@user, option.id)
          assert_equal @conv_1.reload.option, option
        end

        it 'increased viewed count' do
          assert_equal @conv_1.viewed_count, 1
        end

        it 'reschedule after 5 days as interval is DAY:5' do
          option = @d2.options.first
          response = Conversation.fetch(@user, option.id)

          ## Here in response either it should return nil or dialog of
          #  next conversations as current conversation has been finished
          # and flag conversation finished

          #assert_equal response, {conv_id: @conv_1.id,
          #                        dialog_data: @d2.reload.data_attributes}

          assert_equal @conv_1.reload.option, option
          assert_equal @conv_1.scheduled_at, Date.current + 5.days
          assert_equal @conv_1.dialog, @d1
          assert @conv_1.released?
        end

        it 'next time conversation should start from 2nd dialog' do
          @d3 = Dialog.create message: Faker::Lorem.sentence, sub_category: @sub_cat_1,
            options: {'0' => {name: Faker::Lorem.word, interval: 'DAY:3', decision_id: @d2.id}}
          assert_equal @d3.reload.options.count, 1

          @sub_cat_1.dialogs << @d3

          option = @d2.options.first
          assert option.update_attributes({decision_id: @d3.id, interval: nil})

          option = @d3.options.first
          response = Conversation.fetch(@user, option.id)
          @conv_1.reload
          assert_equal @conv_1.scheduled_at, Date.current + 3.days
          assert_equal @conv_1.dialog, @d2
          assert @conv_1.released?
        end

        it 'not reschedule if crossed repeat limit' do
          assert @conv_1.update_attribute(:viewed_count, 3)
          option = @d2.options.first
          assert option.interval.present?

          Conversation.fetch(@user, option.id)

          @conv_1.reload
          assert @conv_1.finished?
        end

        it 'create dependant i.e. after_dialog coversation if not created' do
          @sub_cat = create_dialog
          @sub_cat.update_attributes(starts_on_key: SubCategory::AFTER_DIALOG, starts_on_val: @d2.code,
                                    is_ready_to_schedule: true)

          conv_count = @user.conversations.count
          assert !@user.conversations.where(sub_category: @sub_cat).present?

          option = @d2.options.first
          response = Conversation.fetch(@user, option.id)
          @conv_1.reload
          assert_equal @conv_1.scheduled_at, Date.current + 5.days
          assert_equal @conv_1.dialog, @d1
          assert @conv_1.released?

          assert_equal @user.reload.conversations.count, conv_count + 1
          assert @user.conversations.where(sub_category: @sub_cat).present?
        end

        it 'do not create dependant if its not ready to schedule' do
          @sub_cat = create_dialog
          @sub_cat.update_attributes(starts_on_key: SubCategory::AFTER_DIALOG,
                                     starts_on_val: @d2.code)

          conv_count = @user.conversations.count
          assert !@user.conversations.where(sub_category: @sub_cat).present?

          option = @d2.options.first
          response = Conversation.fetch(@user, option.id)
          @conv_1.reload

          assert_equal @user.reload.conversations.count, conv_count
          assert !@user.conversations.where(sub_category: @sub_cat).present?
        end
      end

      describe 'fetch next conversation' do
        before do
          @sub_cat_1, @sub_cat_2, @sub_cat_3 = 3.times.collect do |num|
            create_dialog
          end

          assert @sub_cat_1.update_attributes({priority: 6, is_ready_to_schedule: true, repeat_limit: 3})
          assert @sub_cat_2.update_attributes({priority: 5, is_ready_to_schedule: true})
          assert @sub_cat_3.update_attributes({priority: 4, is_ready_to_schedule: true})
          class User
            include Mongoid::Document

            has_many :conversations, class_name: 'ChatBot::Conversation', as: :created_for
          end
          @user = User.create()
          Conversation.schedule(@user)
          assert_equal @user.conversations.count, 3

          @conv_1 = @user.conversations.find_by(sub_category: @sub_cat_1)
          @conv_2 = @user.conversations.find_by(sub_category: @sub_cat_2)
          @conv_3 = @user.conversations.find_by(sub_category: @sub_cat_3)
        end

        context 'should return' do
          it 'started conversations' do
            assert @conv_1.update_attributes(scheduled_at: Date.current - 1.day)
            assert @conv_2.update_attributes(scheduled_at: Date.current - 1.day)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 1)
            assert @conv_3.start!
            assert @conv_1.released?
            assert @conv_2.released?

            response = Conversation.fetch(@user)
            d1 = @sub_cat_3.initial_dialog
            assert_equal response, {conv_id: @conv_3.id,
                                    dialog_data: d1.reload.data_attributes}
          end

          it 'released conversation with higher priority' do
            assert_equal @sub_cat_1.priority, 6
            assert_equal @sub_cat_2.priority, 5
            assert_equal @sub_cat_3.priority, 4

            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_3.update_attribute(:priority, 3)

            response = Conversation.fetch(@user)
            d1 = @sub_cat_3.initial_dialog
            assert_equal response, {conv_id: @conv_3.id,
                                    dialog_data: d1.reload.data_attributes}

            assert @conv_3.reload.update_attribute(:aasm_state, 'released')
            assert @conv_2.update_attribute(:priority, 2)

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_2.initial_dialog
            assert_equal response_2, {conv_id: @conv_2.id,
                                    dialog_data: d1.reload.data_attributes}
          end

          it 'released conversation' do
            assert_equal @sub_cat_1.priority, 6
            assert_equal @sub_cat_2.priority, 5
            assert_equal @sub_cat_3.priority, 4

            assert @conv_3.schedule!
            assert @conv_1.released?
            assert @conv_2.released?

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_2.initial_dialog
            assert_equal response_2, {conv_id: @conv_2.id,
                                    dialog_data: d1.reload.data_attributes}
          end

          it 'which is scheduled earlier if have same or higher priority' do
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current, priority: 4, viewed_count: 4)
            assert @conv_2.update_attributes(scheduled_at: Date.current - 2.day, priority: 4, viewed_count: 5)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 4, viewed_count: 3)

            response = Conversation.fetch(@user)
            d1 = @sub_cat_3.initial_dialog
            assert_equal response, {conv_id: @conv_3.id,
                                      dialog_data: d1.reload.data_attributes}
          end

          it 'which is scheduled latest if have higher priority than earlier one' do
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current, priority: 3)
            assert @conv_2.update_attributes(scheduled_at: Date.current - 2.day, priority: 4)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 4)

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_1.initial_dialog
            assert_equal response_2, {conv_id: @conv_1.id,
                                      dialog_data: d1.reload.data_attributes}
          end

          it 'conversation whose viewed count is less' do
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current, priority: 5, viewed_count: 7)
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current, priority: 3, viewed_count: 7)
            assert @conv_2.update_attributes(scheduled_at: Date.current - 2.day, priority: 4, viewed_count: 4)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 4, viewed_count: 4)

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_1.initial_dialog
            assert_equal response_2, {conv_id: @conv_1.id,
                                      dialog_data: d1.reload.data_attributes}
            assert @conv_2.update_attributes(scheduled_at: Date.current - 2.day, priority: 4, viewed_count: 4)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 4, viewed_count: 4)

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_1.initial_dialog
            assert_equal response_2, {conv_id: @conv_1.id,
                                      dialog_data: d1.reload.data_attributes}
          end

          it 'conversation whose viewed count is more but has higher priority' do
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current, priority: 3, viewed_count: 7)
            assert @conv_2.update_attributes(scheduled_at: Date.current - 2.day, priority: 4, viewed_count: 4)
            assert @conv_3.update_attributes(scheduled_at: Date.current - 1.day, priority: 4, viewed_count: 4)

            response_2 = Conversation.fetch(@user)
            d1 = @sub_cat_1.initial_dialog
            assert_equal response_2, {conv_id: @conv_1.id,
                                      dialog_data: d1.reload.data_attributes}
          end

          it 'not return released conversation with date greater than today' do
            assert @conv_3.released?
            assert @conv_1.released?
            assert @conv_2.released?

            assert @conv_1.update_attributes(scheduled_at: Date.current + 1.day)
            assert @conv_2.update_attributes(scheduled_at: Date.current + 2.day)
            assert @conv_3.update_attributes(scheduled_at: Date.current + 1.day)

            response_2 = Conversation.fetch(@user)
            assert_equal response_2, {conv_id: nil,
                                      message: Conversation::BYE}
          end
        end
      end
    end
  end
end
