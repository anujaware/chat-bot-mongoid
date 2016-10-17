module ChatBot
  class Category
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Slug

    include Mongoid::History::Trackable
    track_history :on => [:fields],
                  :modifier_field => :modifier


    field :name, type: String

    has_many :sub_categories, class_name: 'ChatBot::SubCategory'

    slug :name

    index({_slug: 1})

    validates :name, presence: true, uniqueness: {case_sensitive: false}

    before_validation :squish_name, if: "name.present?"

    def squish_name
      self.name = name.squish.capitalize
    end

    def self.find_or_create(cat_name)
      cat_exist = Category.all.detect{|category|
        category if category.name.downcase.strip.gsub(' ', '') == cat_name.downcase.strip.gsub(' ', '')
      }
      category = cat_exist.present? ? cat_exist : Category.create(name: cat_name.strip)
      #category
    end
  end
end
