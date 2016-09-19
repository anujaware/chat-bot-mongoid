module ChatBot
  class Category
    include Mongoid::Document
    field :name, type: String

    has_many :sub_categories, class_name: 'ChatBot::SubCategory'

    validates :name, presence: true, uniqueness: {case_sensitive: false}

    before_validation :squish_name, if: "name.present?"

    def squish_name
      self.name.squish!
    end

  end
end
