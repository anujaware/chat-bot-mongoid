module ChatBot
  class SubCategory
    include Mongoid::Document
    include Mongoid::Slug

    field :name, type: String
    field :description, type: String
    field :repeat_limit, type: Integer, default: 0
    field :interval, type: String

    belongs_to :category, class_name: 'ChatBot::Category'
    belongs_to :initial_dialog, class_name: 'ChatBot::Dialog', foreign_key: :code, inverse_of: nil
    has_many :dialogs, class_name: 'ChatBot::Dialog', foreign_key: :code

    slug :name

    index({_slug: 1})

    validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:category] }
    validates :category, :description, presence: true
    validates :repeat_limit, numericality: {only_integer: true, greater_than: -1}

    #accepts_nested_attributes_for :dialogs

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
