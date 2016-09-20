module ChatBot
  class Dialogue
    include Mongoid::Document

    RESPONSE_TYPES = { 0 => 'Choice', 1 => 'Botcontinue',
                       2 => 'Single line text', 3 => 'Multi line text',
                       4 => 'Dropdown', 5 => 'Date', 6 => 'Attach'}

    MESSAGE_TYPES = ['TEXT', 'VIDEO:YOUTUBE', 'VIDEO:VIMEO', 'LINK', 'IMAGE']

    field :code, type: String
    field :message, type: String
    field :user_input_type, type: Integer, default: 0
    field :message_type, type: String, default: 'TEXT'

    has_many :options, class_name: 'ChatBot::Option'
    belongs_to :sub_category, class_name: 'ChatBot::SubCategory'

    validates :message, presence: true
    validates :user_input_type, inclusion: RESPONSE_TYPES.keys
    validates :message_type, inclusion: MESSAGE_TYPES
    validates :sub_category, presence: true

    def self.generate_code(for_code = nil)
      if for_code.present?
        match_number = for_code.match(/^T(\d*)(\.(\d*))?$/)

        base, precision = match_number[1].to_i, match_number[3]
        precision = precision.to_i if precision.present? # We don't want nil or '' to convert to 0
        existing_codes = Dialogue.all.collect(&:code)

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

  end
end
