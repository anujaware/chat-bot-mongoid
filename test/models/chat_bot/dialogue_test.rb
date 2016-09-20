require './test/test_helper'

module ChatBot
  class DialogueTest < ActiveSupport::TestCase

    should validate_presence_of :message
    should validate_inclusion_of(:user_input_type).
      in_array(Dialogue::RESPONSE_TYPES.keys)
    should validate_inclusion_of(:message_type).
      in_array(Dialogue::MESSAGE_TYPES)

    # TODO: mongoid-minitest not working
    #should belong_to(:sub_category)

    def setup
      @sub_category = SubCategory.new name: 'App Intro', category: Category.new(name: 'Introduction')
      @dialogue = Dialogue.create code: 'T410',
        message: Faker::Lorem.sentence, sub_category: @sub_category
      assert @dialogue.save
    end

    def test_constants
      response_types = Dialogue::RESPONSE_TYPES
      assert_equal response_types.length, 7
      assert_equal response_types[0], 'Choice'
      assert_equal response_types[1], 'Botcontinue'
      assert_equal response_types[2], 'Single line text'
      assert_equal response_types[3], 'Multi line text'
      assert_equal response_types[4], 'Dropdown'
      assert_equal response_types[5], 'Date'
      assert_equal response_types[6], 'Attach'

      message_types = Dialogue::MESSAGE_TYPES
      assert_equal message_types, ['TEXT', 'VIDEO:YOUTUBE', 'VIDEO:VIMEO', 'LINK', 'IMAGE']
    end

    def test_message
      @dialogue.message = ''
      assert_not @dialogue.save
    end

    def test_user_input_type
      assert_equal @dialogue.user_input_type, 0

      @dialogue.user_input_type = Dialogue::RESPONSE_TYPES.keys.max + 1
      assert_not @dialogue.save
    end

    def test_sub_category
      @dialogue.sub_category = nil
      assert_not @dialogue.save
    end

    def test_generate_code
       assert_equal Dialogue.generate_code, 'T411'
    end

    def test_generate_code_for_410
       assert_equal Dialogue.generate_code('T410'), 'T411'
      
       assert Dialogue.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410'), 'T410.1'
      
       assert Dialogue.create code: 'T410.1',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410'), 'T410.2'
      
       assert Dialogue.create code: 'T410.2',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410'), 'T410.3'
    end
    
    def test_generate_code_for_410_1
       assert_equal Dialogue.generate_code('T410.1'), 'T411'
      
       assert Dialogue.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.1'), 'T410.2'
      
       assert Dialogue.create code: 'T410.2',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.1'), 'T410.11'
      
       assert Dialogue.create code: 'T410.11',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.1'), 'T410.12'
      
       assert Dialogue.create code: 'T410.12',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.1'), 'T410.13'
    end
    
    def test_generate_code_for_410_12
       assert_equal Dialogue.generate_code('T410.12'), 'T411'
      
       assert Dialogue.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.12'), 'T410.13'
      
       assert Dialogue.create code: 'T410.13',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.12'), 'T410.121'
      
       assert Dialogue.create code: 'T410.121',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.12'), 'T410.122'
      
       assert Dialogue.create code: 'T410.122',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialogue.generate_code('T410.12'), 'T410.123'
    end
  end
end
