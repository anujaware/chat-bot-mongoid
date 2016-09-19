module ChatBot
  class Dialogue
    include Mongoid::Document
    field :code, type: String
    field :message, type: String
    field :user_input_type, type: String
    field :message_type, type: String
  end
end
