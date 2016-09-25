module ChatBot
  class Option
    include Mongoid::Document
    field :name, type: String
    field :interval, type: String
    field :deprecated, type: Mongoid::Boolean

    belongs_to :dialog, class_name: 'ChatBot::Dialog'
    belongs_to :decision, class_name: 'ChatBot::Dialog', inverse_of: nil, primary_key: :code

    validates :name, presence: true#, if: Proc.new{|option| option.dialog.user_input_type != 'cnt'}
    validates :dialog, presence: true
    validates :decision, inclusion: { in: Proc.new{|option|
      option.dialog.sub_category.dialog_ids }}, allow_blank: true
    validates :interval, format: { with: /\ADAY:(\d+)\z/i }, allow_blank: true
  end
end
