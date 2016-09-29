module ChatBot
  class SubCategory
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Slug

    include Mongoid::History::Trackable
    track_history :on => [:fields],
                  :modifier_field => :modifier

    STARTS_ON = ['after_dialog', 'after_days', 'immediate']

    field :name, type: String
    field :description, type: String
    field :repeat_limit, type: Integer, default: 0
    field :interval, type: String
    field :approval_require, type: Boolean, default: false
    field :priority, type: Integer, default: 1
    field :starts_on_key, type: String, default: :immediate
    field :starts_on_val, type: String
    field :is_ready_to_schedule, type: Boolean, default: false

    belongs_to :category, class_name: 'ChatBot::Category'
    belongs_to :initial_dialog, class_name: 'ChatBot::Dialog', foreign_key: :code, inverse_of: nil
    has_many :dialogs, class_name: 'ChatBot::Dialog', foreign_key: :code

    slug :name

    scope :ready, -> {where(is_ready_to_schedule: true)}

    index({_slug: 1})

    validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:category] }
    validates :category, :description, presence: true #initial_dialog
    validates :repeat_limit, numericality: {only_integer: true, greater_than: -1}
    validates :priority, numericality: {only_integer: true, greater_than: 0, less_than: 11}
    validates :starts_on_key, inclusion: { in: STARTS_ON }

    before_validation :squish_name, if: "name.present?"

    ## Class methods
    def self.start(sub_category)
      dialog = sub_category.initial_dialog
      dialog.data_attributes
    end

    def self.next_dialog(option_id)
      option = Option.find_by(id: option_id)
      return nil if !option or !option.decision
      dialog = option.decision
      dialog.data_attributes
    end

    ## Object methods
    def squish_name
      # Squish doesn't work if name contains new line character in single quote while testing
      # TODO: Fix using gsub if issue occur in application
      self.name.squish!
    end

  end
end
