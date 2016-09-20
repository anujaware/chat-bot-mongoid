module ChatBot
  class Option
    include Mongoid::Document
    field :name, type: String
    field :interval, type: String
    field :deprecated, type: Mongoid::Boolean

    belongs_to :dialogue, class_name: 'ChatBot::Dialogue'
    belongs_to :decision, class_name: 'ChatBot::Dialogue', inverse_of: nil, primary_key: :code

    validates :name, :dialogue, presence: true
    validates :decision, inclusion: { in: Proc.new{|option|
      option.dialogue.sub_category.dialogue_ids
    }}, allow_blank: true
    validates :interval, format: { with: /\ADAY:(\d+)\z/i }, allow_blank: true
  end
end
