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
        header2 = rows.delete_at(0)
        @header = {"code" => 0, "category" => 1, "conversation_name" => 2,
                   'description' => 3, "priority" => 4, "dialog_display_text" => 5,
                   "dialog_message_type" => 6, "dialog_user_input_type" => 7,
                   "option_name" => 8, "starts_on" => 9, "dialog_repeat_limit" => 10,
                   "option_interval" => 11, "option_decision" => 12,
                   "approval_require" => 13, "is_ready" => 14}

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

              @dialog= Dialog.find_or_initialize_by(code: code)
              if current_dialog_code != code
                category = Category.find_or_create("#{get_value('category')}")
                sub_category = SubCategory.find_or_create(category, "#{get_value('conversation_name')}") if category.present?
                sub_category.description = get_value('description')
                approval = get_value('approval_require')
                sub_category.approval_require = approval if approval.present?
                priority = get_value('priority')
                sub_category.priority = priority if priority.present?
                is_ready = get_value('is_ready')
                sub_category.is_ready_to_schedule = is_ready if is_ready.present?

                deprecate_old_options if current_dialog_code != code

                @dialog.sub_category = sub_category
                @dialog.message = get_value('dialog_display_text')
                message_type = get_value('dialog_message_type')
                @dialog.message_type = message_type if message_type.present?
                @dialog.user_input_type = get_value('dialog_user_input_type')
                @dialog.repeat_limit = get_value('dialog_repeat_limit').to_i
                sub_category.save
              end

              #@dialog.data_type = extract_datatype
              #@dialog.starts_on = get_starts_on if current_dialog_code != code

              update_or_create_option
              @dialog.save
              current_dialog_code = code
            end
          end
        end
      end

      def update_or_create_option
        # If option_name is already exist
        decision =  get_value('option_decision').match(/(T\d{1,3}(\.\d{1,3})?)/)
        option = @dialog.options.find_or_initialize_by(name: get_value('option_name'))

        #Need to set decision id to '' in case of update option
        option.decision_id = decision.present? ? decision[1] : ''
        option.interval = get_value('option_interval')
        option.deprecated = false
        option.save
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
