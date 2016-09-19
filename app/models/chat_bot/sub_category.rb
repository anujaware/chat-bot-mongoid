module ChatBot
  class SubCategory
    include Mongoid::Document
    field :name, type: String

    belongs_to :category, class_name: 'ChatBot::Category'

    validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:category] }
    validates :category, presence: true

    before_validation :squish_name, if: "name.present?"

    def squish_name
      # Squish doesn't work if name contains new line character in single quote while testing
      # TODO: Fix using gsub if issue occur in application
      self.name.squish!
    end

  end
end
