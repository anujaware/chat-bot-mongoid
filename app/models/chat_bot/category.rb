module ChatBot
  class Category
    include Mongoid::Document
    include Mongoid::Slug

    field :name, type: String

    has_many :sub_categories, class_name: 'ChatBot::SubCategory'

    slug :name

    validates :name, presence: true, uniqueness: {case_sensitive: false}

    accepts_nested_attributes_for :sub_categories

    before_validation :squish_name, if: "name.present?"

    def squish_name
      self.name.squish!
    end

  end
end
