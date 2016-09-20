require './test/test_helper'

module ChatBot
  class DialogueTest < ActiveSupport::TestCase

    should validate_presence_of :message
    should validate_inclusion_of(:user_input_type).
      in_array(Dialogue::RESPONSE_TYPES.keys)
    should validate_inclusion_of(:message_type).
      in_array(Dialogue::MESSAGE_TYPES)

    def setup
      @dialogue = Dialogue.create code: 'T410', message: Faker::Lorem.sentence
      assert @dialogue.save
    end

    def test_constants
      response_types = Dialogue::RESPONSE_TYPES
      assert_equal response_types.length, 5
      assert_equal response_types[0], 'Choice'
      assert_equal response_types[1], 'Single line text'
      assert_equal response_types[2], 'Multi line text'
      assert_equal response_types[3], 'Dropdown'
      assert_equal response_types[4], 'Date'

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

    def test_generate_code
       assert_equal Dialogue.generate_code, 'T411'
    end

    def test_generate_code_for_410
       assert_equal Dialogue.generate_code('T410'), 'T411'
      
       assert Dialogue.create code: 'T411', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410'), 'T410.1'
      
       assert Dialogue.create code: 'T410.1', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410'), 'T410.2'
      
       assert Dialogue.create code: 'T410.2', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410'), 'T410.3'
    end
    
    def test_generate_code_for_410_1
       assert_equal Dialogue.generate_code('T410.1'), 'T411'
      
       assert Dialogue.create code: 'T411', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.1'), 'T410.2'
      
       assert Dialogue.create code: 'T410.2', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.1'), 'T410.11'
      
       assert Dialogue.create code: 'T410.11', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.1'), 'T410.12'
      
       assert Dialogue.create code: 'T410.12', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.1'), 'T410.13'
    end
    
    def test_generate_code_for_410_12
       assert_equal Dialogue.generate_code('T410.12'), 'T411'
      
       assert Dialogue.create code: 'T411', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.12'), 'T410.13'
      
       assert Dialogue.create code: 'T410.13', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.12'), 'T410.121'
      
       assert Dialogue.create code: 'T410.121', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.12'), 'T410.122'
      
       assert Dialogue.create code: 'T410.122', message: Faker::Lorem.sentence
       assert_equal Dialogue.generate_code('T410.12'), 'T410.123'
    end
  end
end
