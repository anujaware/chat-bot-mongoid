module ChatBot
  class Option
    include Mongoid::Document
    include Mongoid::Timestamps

    include Mongoid::History::Trackable
    track_history :on => [:fields],
                  :modifier_field => :modifier

    field :name, type: String
    field :interval, type: String
    field :deprecated, type: Mongoid::Boolean, default: false

    belongs_to :dialog, class_name: 'ChatBot::Dialog'
    belongs_to :decision, class_name: 'ChatBot::Dialog', inverse_of: nil, primary_key: :code

    validates :name, presence: true#, if: Proc.new{|option| option.dialog.user_input_type != 'cnt'}
    validates :dialog, presence: true
    validates :decision_id, inclusion: { in: Proc.new{|option|
      option.dialog.sub_category.dialogs.collect(&:code) }}, allow_blank: true
    validates :interval, format: { with: /\ADAY:(\d+)\z/i }, allow_blank: true
  end

  def self.deprecate!
    update_all(deprecated: true)
  end
end
