module ChatBot
  class SubCategory
    include Mongoid::Document
    include Mongoid::Slug

    field :name, type: String
    field :description, type: String
    field :repeat_limit, type: Integer, default: 0
    field :interval, type: String

    belongs_to :category, class_name: 'ChatBot::Category'
    has_many :dialogues, class_name: 'ChatBot::Dialogue', foreign_key: :code

    slug :name

    index({_slug: 1})

    validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:category] }
    validates :category, :description, presence: true
    validates :repeat_limit, numericality: {only_integer: true, greater_than: -1}

    accepts_nested_attributes_for :dialogues

    before_validation :squish_name, if: "name.present?"

    def squish_name
      # Squish doesn't work if name contains new line character in single quote while testing
      # TODO: Fix using gsub if issue occur in application
      self.name.squish!
    end

  end
end
