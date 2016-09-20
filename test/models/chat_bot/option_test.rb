require './test/test_helper'

module ChatBot
  class OptionTest < ActiveSupport::TestCase

    should_not allow_value('DA:3').for(:interval)
    should_not allow_value('3').for(:interval)

    def setup
      @sub_category = SubCategory.create name: 'App Intro',
        category: Category.new(name: 'Introduction')
      @dialogue = Dialogue.new code: 'T20', message: Faker::Lorem.sentence,
        sub_category: @sub_category#, options: [Option.new(name: Faker::Lorem.word)]
      @option = Option.new name: Faker::Lorem.word, dialogue: @dialogue
    end

    def test_name
      @option.name = ''
      assert_not @option.save

      @dialogue.user_input_type = 1
      @dialogue.save

      @option.name = Faker::Lorem.word
      assert @option.save
    end

    def test_parent_dialogue
      @option.dialogue = nil
      assert_not @option.save
    end

    def test_decision
      @option.decision = nil
      assert @option.save

      @dialogue = Dialogue.new code: 'T40', message: Faker::Lorem.sentence, sub_category: @sub_category
      dialogue_codes = @sub_category.dialogue_ids
      @option.decision_id = 'T20'
      assert_not @option.save

      @option.decision_id = dialogue_codes.sample
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
