module ChatBot
  class Conversation
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM

    include Mongoid::History::Trackable
    track_history :on => [:fields],
                  :modifier_field => :modifier

    field :aasm_state
    field :viewed_count, type: Integer, default: 0
    field :scheduled_at, type: DateTime
    field :priority, type: Integer, default: 1

    belongs_to :sub_category, class_name: 'ChatBot::SubCategory', inverse_of: nil
    belongs_to :dialog, class_name: 'ChatBot::Dialog', foreign_key: :code, inverse_of: nil
    belongs_to :created_for, polymorphic: true

    # To maintain history of selected option by the user
    belongs_to :option, class_name: 'ChatBot::Option', inverse_of: nil

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
        transitions :from => [:started, :released], :to => :finished
      end

      event :reschedule do
        transitions :from => [:started], :to => :released
      end
    end

    validates :sub_category, :dialog, presence: true
    validates :viewed_count, numericality: { only_integer: true, greater_than: -1 }
    validates :sub_category, uniqueness: { scope: :created_for}

    # There is atmost one started conversation can be exists for an object
    scope :current,-> { where(aasm_state: 'started')}

    before_validation :set_defaults, on: :create
    before_save :reset, if: "aasm_state_changed? and aasm_state_change.first == 'started' and
                             aasm_state_change.last == 'released'"

    # Class methods
    def self.schedule(user)
      SubCategory.ready.each do |sub_cat|
        scheduled_date = calculate_scheduled_date(sub_cat.starts_on_key, sub_cat.starts_on_val)
        if scheduled_date.present?
          assign(user, sub_cat, scheduled_date)
        end
      end
    end

    def self.assign(user, sub_category, scheduled_date)
      conversation = user.conversations.find_or_create_by({sub_category: sub_category})
      state = sub_category.approval_require ? 'scheduled' : 'released'
      conversation.update_attributes({scheduled_at: scheduled_date,
                                      aasm_state: state})
    end

    def self.calculate_scheduled_date(starts_on_key, value)
      self.send(starts_on_key, value)
    end

    def self.after_dialog(dialog_code)
    end

    def self.after_days(num)
      Date.current + num.to_i.days
    end

    def self.immediate(useless)
      Date.current
    end

    def self.fetch(created_for, option_id = nil)
      if option_id.present?
        conv = created_for.conversations.current.first
        conv.update_attribute(:option_id, option_id)
        option = conv.option

        opt_interval = option.interval
        opt_decision = option.decision

        if opt_interval.present?
          ## Move this to a method and use it as a aasm call back on reschedule
          conv.reschedule!
          conv.reload
          interval = opt_interval.match(/DAY:(\d+)/)[1].to_i
          conv.scheduled_at = Date.current + interval.days
          conv.dialog = opt_decision ? opt_decision : conv.sub_category.initial_dialog
        else
          conv.dialog = opt_decision
        end
      else
        conv = created_for.conversations.first
        conv.start!
      end

      conv.save
      if !conv.started?
        {conv_id: conv.id,
         finished: true}
      else
        {conv_id: conv.id,
         dialog_data: conv.dialog.data_attributes}
      end
    end

    # Object methods
    def increase_viewed_count
      self.viewed_count += 1
      save
    end

    def set_defaults
      restart
      #self.priority = sub_category.priority
      # TODO: Not working. self.save goes in inifinite loop
      #self.initial_dialog = sub_category.initial_dialog
      self.schedule! if sub_category.try(:approval_require)
    end

    def restart
      self.dialog = sub_category.try(:initial_dialog)
    end

    def reset
      self.finish! if viewed_count >= sub_category.repeat_limit
      sub_categories = SubCategory.where(starts_on_key: SubCategory::AFTER_DIALOG,
                                        starts_on_val: dialog.code)
      sub_categories.each do |sub_cat|
        Conversation.assign(created_for, sub_cat, Date.current)
      end
    end

  end
end
