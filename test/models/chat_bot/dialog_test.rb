require './test/test_helper'

module ChatBot
  class DialogTest < ActiveSupport::TestCase

    should validate_presence_of :message
    should validate_inclusion_of(:user_input_type).
      in_array(Dialog::RESPONSE_TYPES.keys)
    should validate_inclusion_of(:message_type).
      in_array(Dialog::MESSAGE_TYPES.keys)

    # TODO: mongoid-minitest not working
    #should belong_to(:sub_category)

    def setup
      @sub_category = SubCategory.new name: 'App Intro', category: Category.new(name: 'Introduction')
      @dialog = Dialog.create code: 'T410',
        message: Faker::Lorem.sentence, sub_category: @sub_category
      assert @dialog.save
    end

    def test_constants
      response_types = Dialog::RESPONSE_TYPES
      assert_equal response_types.length, 7
      assert_equal response_types['ch'], 'Choice'
      assert_equal response_types['cnt'], 'Botcontinue'
      assert_equal response_types['slt'], 'Single line text'
      assert_equal response_types['mlt'], 'Multi line text'
      assert_equal response_types['ddw'], 'Dropdown'
      assert_equal response_types['date'], 'Date'
      assert_equal response_types['attach'], 'Attach'

      message_types = Dialog::MESSAGE_TYPES
      assert_equal message_types, { 'txt' => 'TEXT', 'utube' => 'VIDEO:YOUTUBE',
                      'vimeo' => 'VIDEO:VIMEO', 'link' => 'LINK', 'img' => 'IMAGE'}
    end

    def test_message
      @dialog.message = ''
      assert_not @dialog.save
    end

    def test_user_input_type
      assert_equal @dialog.user_input_type, 'ch'

      @dialog.user_input_type = Faker::Lorem.word
      assert_not @dialog.save
    end

    def test_options_of_botcontinue_dialogue
      #TODO Dialogue of type botcontinue should have only one non deprecated option
    end

    def test_sub_category
      @dialog.sub_category = nil
      assert_not @dialog.save
    end

    def test_before_save
      Dialog.destroy_all
      dialog = Dialog.create message: Faker::Lorem.sentence, sub_category: @sub_category
      assert dialog.save
      assert_equal dialog.code, 'T1'
    end

    def test_generate_code
       assert_equal Dialog.generate_code, 'T411'
    end

    def test_generate_code_for_410
       assert_equal Dialog.generate_code('T410'), 'T411'
      
       assert Dialog.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410'), 'T410.1'
      
       assert Dialog.create code: 'T410.1',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410'), 'T410.2'
      
       assert Dialog.create code: 'T410.2',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410'), 'T410.3'
    end
    
    def test_generate_code_for_410_1
       assert_equal Dialog.generate_code('T410.1'), 'T411'
      
       assert Dialog.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.1'), 'T410.2'
      
       assert Dialog.create code: 'T410.2',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.1'), 'T410.11'
      
       assert Dialog.create code: 'T410.11',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.1'), 'T410.12'
      
       assert Dialog.create code: 'T410.12',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.1'), 'T410.13'
    end
    
    def test_generate_code_for_410_12
       assert_equal Dialog.generate_code('T410.12'), 'T411'
      
       assert Dialog.create code: 'T411',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.12'), 'T410.13'
      
       assert Dialog.create code: 'T410.13',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.12'), 'T410.121'
      
       assert Dialog.create code: 'T410.121',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.12'), 'T410.122'
      
       assert Dialog.create code: 'T410.122',
         message: Faker::Lorem.sentence, sub_category: @sub_category
       assert_equal Dialog.generate_code('T410.12'), 'T410.123'
    end
  end
end
