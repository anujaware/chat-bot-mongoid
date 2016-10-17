require './test/test_helper'
require './lib/chat_bot/import_dialogs'

module ChatBot
  class ImportdialogsTest < ActiveSupport::TestCase

    describe 'import dialog CSV' do
      before do
        class TestDialogImport
          include ImportDialogs
        end
        TestDialogImport.import('./test/fixtures/chat_bot/files/dialog_test.csv')
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

      context 'user_input_type of' do
        it 'T1 should be "ch"' do
          dilog = Dialog.find_by(code: 'T1')
          assert dilog.user_input_type, 'ch'
        end

        it 'T2 should be "cnt"' do
          dilog = Dialog.find_by(code: 'T2')
          assert dilog.user_input_type, 'cnt'
        end

        it 'T3 should be "slt"' do
          dilog = Dialog.find_by(code: 'T3')
          assert dilog.user_input_type, 'slt'
        end

        it 'T4 should be "mlt"' do
          dilog = Dialog.find_by(code: 'T4')
          assert dilog.user_input_type, 'mlt'
        end

        it 'T5 should be "ddw"' do
          dilog = Dialog.find_by(code: 'T5')
          assert dilog.user_input_type, 'ddw'
        end

        it 'T6 should be "date"' do
          dilog = Dialog.find_by(code: 'T6')
          assert dilog.user_input_type, 'date'
        end

        it 'T7 should be "attach"' do
          dilog = Dialog.find_by(code: 'T7')
          assert dilog.user_input_type, 'attach'
        end
      end

      context 'message_type of' do
        it 'T2 should be "txt"' do
          dilog = Dialog.find_by(code: 'T1')
          assert dilog.message_type, 'txt'
        end

        it 'T3 should be "utube"' do
          dilog = Dialog.find_by(code: 'T3')
          assert dilog.user_input_type, 'utube'
        end

        it 'T4 should be "vimeo"' do
          dilog = Dialog.find_by(code: 'T4')
          assert dilog.user_input_type, 'vimeo'
        end

        it 'T5 should be "link"' do
          dilog = Dialog.find_by(code: 'T5')
          assert dilog.user_input_type, 'link'
        end

        it 'T6 should be "img"' do
          dilog = Dialog.find_by(code: 'T6')
          assert dilog.user_input_type, 'img'
        end
      end

      context 'dialog T1 should have 3 options having' do
        context 'one option with' do
          it 'name "Ok"' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Ok')
            assert option.present?
          end

          it 'interval "DAY:3"' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Ok')
            assert_equal option.interval, 'DAY:3'
          end

          it 'decision T2' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Ok')
            assert_equal option.decision, Dialog.find_by(code: 'T2')
          end
        end

        context 'second option with' do
          it 'name "Yes"' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Yes')
            assert option.present?
          end

          it 'interval "DAY:1"' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Yes')
            assert_equal option.interval, 'DAY:3'
          end 

          it 'decision T2' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'Yes')
            assert_equal option.decision, Dialog.find_by(code: 'T2')
          end
        end
        context 'third option with' do
          it 'name "No"' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'No')
            assert option.present?
          end

          it "interval ''(empty/nil)" do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'No')
            assert !option.interval.present?
          end

          it 'decision T3' do
            dilog = Dialog.find_by(code: 'T1')
            option = dilog.options.find_by(name: 'No')
            assert_equal option.decision, Dialog.find_by(code: 'T3')
          end
        end
      end

      context 'dialog T2 should have 2 options having' do
        context 'one option with' do
          it 'name "Yes"' do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'Yes')
            assert option.present?
          end

          it 'interval "DAY:2"' do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'Yes')
            assert_equal option.interval, 'DAY:2'
          end

          it 'decision T2' do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'Yes')
            assert !option.decision.present?
          end
        end

        context 'second option with' do
          it 'name "No"' do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'No')
            assert option.present?
          end

          it "interval ''(empty/nil)" do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'No')
            assert !option.interval.present?
          end

          it 'decision T3' do
            dilog = Dialog.find_by(code: 'T2')
            option = dilog.options.find_by(name: 'No')
            assert_equal option.decision, Dialog.find_by(code: 'T3')
          end
        end
      end

      ## Negative specs
      it 'should fail if dialog code is 12'
      it 'multiple dialogs with same code shoule not exists'
      it "should throw error if doesn't matches format"

    end
  end
end
