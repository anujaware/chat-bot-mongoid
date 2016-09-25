require './test/test_helper'

module ChatBot
  class ConversationTest < ActiveSupport::TestCase
=begin    
    ### Specs for
    ### Normal conversations with some options
    ###   1. Choice
    ###   2. Bot continue
    ###   3. Single line text
    ###   4. Multi line text
    ###   5. Dropdown
    ###   6. Date
    ###   7. Attach

    ### Msg types
    ###   1. Text
    ###   2. Youtube video link
    ###   3. Vimeo
    ###   4. Link
    ###   5. Image

   Should not return deprecated options

   Future Add replaceable text
=end

    def setup
      @sub_cat = SubCategory.new name: 'App Intro', category: Category.new(name: 'Introduction')
      @msg_1 = "What would you like to do?"
      @dialog_1 = Dialog.create(sub_category: @sub_cat, message: @msg_1, user_input_type: 'ch')

      @op_11 = 'Play music'
      @op_12 = 'Sleep tight!'
      @option_11 = Option.create(name: @op_11, dialog: @dialog_1)
      @option_12 = Option.create(name: @op_12, dialog: @dialog_1)
    end

    def test_start
      assert_equal Conversation.start(@sub_cat), { id: 't1', message: @msg_1, user_input_type: :ch, formatted_message: @msg_1,
                                                   options: [{id: @option_11.id, name: @op_11, decision: nil},
                                                             {id: @option_12.id, name: @op_12, decision: nil}]
                                                 }
    end

    def test_next_dialog
      msg_2 = 'Ok, Which artist?'
      dialog_2 = Dialog.create(sub_category: @sub_cat, message: msg_2, user_input_type: 'ch')
      op_21 = 'Shreya Ghoshal'
      op_22 = 'Katy Perry'
      option_21 = Option.create(name: op_21, dialog: dialog_2)
      option_22 = Option.create(name: op_22, dialog: dialog_2)
      option_json = [{id: option_21.id, name: op_21, decision: nil}, {id: option_22.id, name: op_22, decision: nil}]

      @option_11.decision = dialog_2

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :ch,
                                                                formatted_message: @msg_1,
                                                                options: option_json}
    end

    def test_data_attributes
      msg_2 = 'Ok, Which artist?'
      dialog_2 = Dialog.create(sub_category: @sub_cat, message: msg_2, user_input_type: 'ch')
      op_21 = 'Shreya Ghoshal'
      op_22 = 'Katy Perry'
      option_21 = Option.create(name: op_21, dialog: dialog_2)
      option_22 = Option.create(name: op_22, dialog: dialog_2)
      option_json = [{id: option_21.id, name: op_21, decision: nil}, {id: option_22.id, name: op_22, decision: nil}]

      @option_11.decision = dialog_2

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :ch,
                                                                formatted_message: msg_2,
                                                                options: option_json}
      ## Botcontinue + Youtube video
      msg_2 = 'aBcd-eFg'
      dialog_2.update_attibutes(message: msg_2, user_input_type: 'cnt', message_type: 'utube')

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :cnt,
                                                                formatted_message: "<iframe width='229' height='200' src='https://www.youtube.com/embed/aBcd-eFg' frameborder='0' allowfullscreen></iframe>", options: option_json}

      ## Single line input  + Vimeo video
      msg_2 = '1234321'
      dialog_2.update_attibutes(message: msg_2, user_input_type: 'slt', message_type: 'vimeo')

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :slt,
                                                                formatted_message: "<iframe width='229' height='200' src='https://player.vimeo.com/video/#{msg_2}' frameborder='0' webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>",
                                                                options: option_json}
      ## Multiline input  + Link
      msg_2 = 'https://github.com/anujaware'
      dialog_2.update_attibutes(message: msg_2, user_input_type: 'mlt', message_type: 'link')

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :mlt,
                                                                formatted_message: "<a href='#{msg_2}' target='_'>Click here.</a>",
                                                                options: option_json}
      ## Dropdown + Image
      msg_2 = "http://media2.intoday.in/indiatoday/images/stories/collagea_647_083016020529.jpg"
      dialog_2.update_attibutes(message: msg_2, user_input_type: 'ddw', message_type: 'img')

      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :ddw,
                                                                formatted_message: "<img src=#{msg_2}/>",
                                                                options: option_json}

      ## Attachment
      dialog_2.update_attibutes(user_input_type: 'attach')
      assert_equal Conversation.next_dialogue(@option_11.id), { id: 't2', message: msg_2, user_input_type: :attach,
                                                                formatted_message: "<img src=#{msg_2}/>",
                                                                options: option_json}
    end
  end
end
