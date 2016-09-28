module ChatBot
  class Conversation
    include Mongoid::Document
    include AASM

    field :aasm_state
    field :viewed_count, type: Integer, default: 0

    belongs_to :sub_category, class_name: 'ChatBot::SubCategory', inverse_of: nil
    belongs_to :dialog, class_name: 'ChatBot::Dialog', foreign_key: :code, inverse_of: nil
    belongs_to :created_for, polymorphic: true

    aasm do
      state :scheduled, :initial => true
      state :released
      state :started
      state :finished

      event :schedule do
        transitions :to => :scheduled
      end

      event :release do
        transitions :from => [:added, :finished, :scheduled], :to => :released
      end

      event :start do
        transitions :from => [:released, :scheduled], :to => :started, after: :increase_viewed_count
      end

      event :finish do
        # On finish either finish or reschedule conversation as per the condition
        # conditions are: if 'interval' is present in selected option of the dialog
        # and have not exceeded repeat limit of the [dialog/conversation???]
        transitions :from => :started, :to => :finished#, after: :reset_and_reschedule
      end

      #event :reschedule do
      #  transitions :from => [:started, :finished], :to => :released, after: :update_conversation_on_reschedule
      #end
    end

    validates :sub_category, :dialog, presence: true
    validates :viewed_count, numericality: { only_integer: true, greater_than: -1 }

    def increase_viewed_count
      self.viewed_count += 1
      save
    end

  end
end
