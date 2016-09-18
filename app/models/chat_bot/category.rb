module ChatBot
  class Category
    include Mongoid::Document
    field :name, type: String
    validates :name, presence: true, uniqueness: {case_sensitive: false}

    before_validation :strip_name

    def strip_name
      self.name# = name.truncate
    end

  end
end
