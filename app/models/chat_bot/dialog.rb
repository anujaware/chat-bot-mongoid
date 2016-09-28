module ChatBot
  class Dialog
    include Mongoid::Document
    include Mongoid::Slug

    include Mongoid::History::Trackable
    track_history :modifier_field => :modifier


    slug do |cur_object|
      cur_object.code.gsub('.', '_').to_url
    end

    RESPONSE_TYPES = { 'ch' => 'Choice', 'cnt' => 'Botcontinue',
                       'slt' => 'Single line text', 'mlt' => 'Multi line text',
                       'ddw' => 'Dropdown', 'date' => 'Date', 'attach' => 'Attach'}

    MESSAGE_TYPES = { 'txt' => 'TEXT', 'utube' => 'VIDEO:YOUTUBE',
                      'vimeo' => 'VIDEO:VIMEO', 'link' => 'LINK', 'img' => 'IMAGE'}

    field :code, type: String
    field :message, type: String
    field :user_input_type, type: String, default: 'ch'
    field :message_type, type: String, default: 'txt'

    has_many :options, class_name: 'ChatBot::Option', primary_key: :code, inverse_of: :dialog
    belongs_to :sub_category, class_name: 'ChatBot::SubCategory'

    attr_accessor :parent_dialog_code

    index({_slug: 1})

    validates :message, presence: true
    validates :user_input_type, inclusion: RESPONSE_TYPES.keys
    validates :message_type, inclusion: MESSAGE_TYPES.keys
    validates :sub_category, presence: true

    before_validation :set_dialog_code, on: :create
    #accepts_nested_attributes_for :options

    ## Class methods
    def self.generate_code(for_code = nil)
      if for_code.present?
        match_number = for_code.match(/^T(\d*)(\.(\d*))?$/)

        base, precision = match_number[1].to_i, match_number[3]
        precision = precision.to_i if precision.present? # We don't want nil or '' to convert to 0
        existing_codes = all.collect(&:code)

        # Logic will work as follows:
        # if for_code is T123.45 will return
        #   T124 if doesn't exists
        #   otherwise will return T123.46 if doens't exists
        #   otherwise will return T123.451 or T123.452 or T123.452... and so on

        case true
        when !existing_codes.include?("T#{base+1}")
          return "T#{base+1}"
        when (precision.present? and !existing_codes.include?("T#{base}.#{precision+1}"))
          return "T#{base}.#{precision+1}"
        else
          next_precision = "#{precision}1".to_i
          loop do
            next_code = "T#{base}.#{next_precision}"
            return next_code if !existing_codes.include?(next_code)
            next_precision += 1
          end
        end
      else
        "T#{all.collect{|d| d.code.split('.').first.gsub('T', '').to_i}.sort.last.to_i + 1}"
      end
    end

    ## Object methods
    def set_dialog_code
      self.code = Dialog.generate_code(parent_dialog_code) if code.nil?
    end

    def data_attributes
      { id: slug, message: message,
        user_input_type: user_input_type,
        formatted_message: formatted_message,
        options: options.collect{|option|
          {id: option.id, name: option.name}
        }
      }
    end

    def formatted_message
      case message_type
      when 'utube'
        "<iframe width='229' height='200' src='https://www.youtube.com/embed/#{message}' frameborder='0' allowfullscreen></iframe>"
      when 'vimeo'
        "<iframe width='229' height='200' src='https://player.vimeo.com/video/#{message}' frameborder='0' webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
      when 'link'
        "<a href='#{message}' target='_'>Click here.</a>"
      when 'img'
        "<img src=#{message}/>"
      else
        message
      end
    end

  end
end
