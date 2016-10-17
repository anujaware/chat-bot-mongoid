require 'csv'
module ChatBot
  module ImportDialogs
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def import(file_path, new_dialogs = true)
        file = CSV.open(file_path, :row_sep => :auto, :col_sep => ",")
        rows = file.read
        header1 = rows.delete_at(0)
        p header1
        header2 = rows.delete_at(0)
        @header = {"code" => 0, "category" => 1, "conversation_name" => 2,
                   'description' => 3, "display_text" => 4, "message_type" => 5,
                   "user_input_type" => 6, "option_name" => 7, "starts_on" => 8,"priority"=> 9,
                   "option_interval" => 10, "option_repeat_limit" => 11,
                   "option_decision" => 12, "approval_require" => 13}

        found_mismatch = false
        @header.each do |key, value|
          if !header1 or header1[value] != key
            found_mismatch = true
            p key
            p value
            p header1[value] if header1
          end
          p 'Header mismatch' and break if found_mismatch
        end

        if new_dialogs
          rows.each do |row|
            code = row[@header['code']]
            if Dialog.where(code: row[@header['code']]).present?
              p "#{code} exists in the database."
              found_mismatch = true
            end
          end
        end

        if !found_mismatch
          current_dialog_code = nil
          rows.each do |row|
            @row = row
            code = get_value('code').try(:strip)

            if code.present? and code.match(/^T\d*(\.\d*)?$/).present?
              category = Category.find_or_create("#{get_value('category')}")
              sub_category = SubCategory.find_or_create(category, "#{get_value('conversation_name')}") if category.present?

              @dialog= Dialog.find_or_initialize_by(code: code)

              deprecate_old_options if current_dialog_code != code

              @dialog.sub_category = sub_category if current_dialog_code != code
              description = get_value('description')
              sub_category.description = description if description
              
              priority = get_value('priority')
              sub_category.priority = priority if priority
              
              approval = get_value('approval_require')
              sub_category.approval_require = approval_require if approval

              ##CHECK: @dialog.priority = priority.to_i if priority.present? and current_dialogue_code != code

              @dialog.message = get_value('display_text')
              @dialog.message_type = get_value('message_type')
              @dialog.user_input_type = get_value('user_input_type')

              ######@header = {"code" => 0, "category" => 1, "conversation_name" => 2,
              ######           'description' => 3, "display_text" => 4, "message_type" => 5,
              #           "user_input_type" => 6, "option_name" => 7, "starts_on" => 8,"priority"=> 9,
              #           "option_interval" => 10, "option_repeat_limit" => 11,
              #           "option_decision" => 12, "approval_require" => 13}

              #@dialog.data_type = extract_datatype
              #@dialog.starts_on = get_starts_on if current_dialogue_code != code

              ### CHECK: 
              #####repeat_limit = get_value('option_repeat_limit').match(/(\d+)/)
              #####@dialog.repeat_limit = repeat_limit[1] if repeat_limit.present?


              update_or_create_option
              @dialogue.save
              current_dialogue_code = code
            end
          end
        end
      end

      def get_value(header_name)
        "#{@row[@header[header_name]]}"
      end

      def deprecate_old_options
        if @dialog.options.present?
          @dialog.options.deprecate!
        end
      end

    end
  end
end
