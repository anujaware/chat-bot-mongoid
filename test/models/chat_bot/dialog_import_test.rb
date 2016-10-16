require './test/test_helper'

module ChatBot
  class DialogImportTest < ActiveSupport::TestCase
=begin
  1. dialog code
     1. should throw error if format doesn't match
     2. if same code on muliple places then should
        i. save once for unique code
       ii. should save multiple options
     3. Save category -> name should match
     4. Category should have subcateogires
     5. Sub category should have X number of dialogs -> Name should match 
     6. Test each dialog for all the information
     7. Create few dialogs which covers all possibilities
       i. code
       ii. message
       iii. user input type = ch/cnt/slt/mlt/ddw/date/attach
           should throw error if exits wrong format
       iv. messsage type = txt/utube/vimeo/link/img
       v. options
       vi. sub category
=end
    describe 'import dialog CSV' do
      before do
        ImportDialogs.import(Rails.root + 'test/fixtures/chat_bot/files/dialog_test.csv')
      end
      
      context 'category "Introduction" should' do
        it 'exists' do
          Category.find_by(name: 'Introduction')
        end

        it 'have sub category "App Introduction"' do
          SubCategory.find_by(name: 'Application Introduction')
        end

        it 'have sub category "App Introduction"' do
          SubCategory.find_by(name: 'Application Usage')
        end
      end

      context 'category "Insurance" should' do
        it 'exists' do
          Category.find_by(name: 'Insurance')
        end

        it 'have sub category "Car Insurance"' do
          SubCategory.find_by(name: 'Car Insurance')
        end
      end

      it 'sub category "App Introduciton" should have X no. of dialogs' do
        sub_category = SubCategory.find_by(name: 'Application Introduction')
        assert sub_category.dialogs.count, 5
      end

      it 'dialog should exists of code "T1"' do
        sub_category = SubCategory.find_by(name: 'Application Introduction')
        dialog = Dialog.find_by(code: 'T1')
        assert dialog.present?
        assert_equal dialog.sub_category, sub_category
      end

      ## CREATE A SET OF DIALOGS IN EXCEL SHEET and Match each and everything
      context 'dialog T1 should have 3 options having' do
        it 'name = "Ok"'
        it 'name = "Yes"'
        it 'name = "No"'
      end
    end
    
    ## Negative specs
    it 'should fail if dialog code is 12'
    it 'multiple dialogs with same code shoule not exists'

  end
end
