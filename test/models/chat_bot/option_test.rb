require './test/test_helper'

module ChatBot
  class OptionTest < ActiveSupport::TestCase

    should_not allow_value('DA:3').for(:interval)
    should_not allow_value('3').for(:interval)

    def setup
      @sub_category = SubCategory.create name: 'App Intro',
        category: Category.new(name: 'Introduction')
      @dialog = Dialog.new code: 'T20', message: Faker::Lorem.sentence,
        sub_category: @sub_category#, options: [Option.new(name: Faker::Lorem.word)]
      @option = Option.new name: Faker::Lorem.word, dialog: @dialog
    end

    def test_name
      @option.name = ''
      assert_not @option.save

      @dialog.user_input_type = 1
      @dialog.save

      @option.name = Faker::Lorem.word
      assert @option.save
    end

    def test_parent_dialog
      @option.dialog = nil
      assert_not @option.save
    end

    def test_decision
      @option.decision = nil
      assert @option.save

      @dialog = Dialog.new code: 'T40', message: Faker::Lorem.sentence, sub_category: @sub_category
      dialog_codes = @sub_category.dialogs.collect(&:code)
      @option.decision_id = 'T120'
      assert_not @option.save, 'Decision id is not from valid list'

      @option.decision_id = dialog_codes.sample
      assert @option.save
    end

    def test_interval
      # format DAY:[Number]
      @option.interval = 'DA:23'
      assert_not @option.save

      @option.interval = 'DAY:21'
      assert @option.save
    end
  end
end
