module ChatBot
  class SubCategory
    include Mongoid::Document
    field :name, type: String
    field :description, type: String
    field :repeat_limit, type: Integer, default: 0

    belongs_to :category, class_name: 'ChatBot::Category'

    validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:category] }
    validates :category, :description, presence: true
    validates :repeat_limit, numericality: {only_integer: true, greater_than: -1}

    before_validation :squish_name, if: "name.present?"

    def squish_name
      # Squish doesn't work if name contains new line character in single quote while testing
      # TODO: Fix using gsub if issue occur in application
      self.name.squish!
    end

  end
end
