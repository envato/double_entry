# # encoding: utf-8
# require "spec_helper"
#
# describe EncapsulateAsMoney do
#
#   Given(:model_base_class_with_attr) {
#     Class.new {
#       extend EncapsulateAsMoney
#       attr_accessor :attribute
#     }
#   }
#   Given(:model_instance) { model_class.new }
#   Given!(:init_attr_value) { model_instance.instance_variable_set :@attribute, initial_attr_value }
#
#   describe "encapsulating the attribute as money" do
#     When(:model_class) {
#       Class.new(model_base_class_with_attr) {
#         encapsulate_as_money :attribute
#       }
#     }
#
#     context "initial value is nil" do
#       Given(:initial_attr_value) { nil }
#       Then { model_instance.attribute == Money.new(0) }
#     end
#
#     context "initial value is 0" do
#       Given(:initial_attr_value) { 0 }
#       Then { model_instance.attribute == Money.new(0) }
#     end
#
#     context "initial value is 1" do
#       Given(:initial_attr_value) { 1 }
#       Then { model_instance.attribute == Money.new(1) }
#     end
#   end
#
#   describe "encapsulating the attribute as money, preserving nil" do
#     When(:model_class) {
#       Class.new(model_base_class_with_attr) {
#         encapsulate_as_money :attribute, :preserve_nil => true
#       }
#     }
#
#     context "initial value is nil" do
#       Given(:initial_attr_value) { nil }
#       Then { model_instance.attribute == nil }
#     end
#
#     context "initial value is 0" do
#       Given(:initial_attr_value) { 0 }
#       Then { model_instance.attribute == Money.new(0) }
#     end
#
#     context "initial value is 1" do
#       Given(:initial_attr_value) { 1 }
#       Then { model_instance.attribute == Money.new(1) }
#     end
#   end
#
#   describe "currency" do
#     When(:model_class) {
#       Class.new(model_base_class_with_attr) {
#         encapsulate_as_money :attribute
#         attr :currency
#       }
#     }
#     Given!(:initial_currency_set) { model_instance.instance_variable_set :@currency, initial_currency_value }
#     Given(:initial_attr_value) { 1 }
#
#     context "Currency Initial value is 1 AUD" do
#       When(:initial_currency_value) { 'AUD' }
#       Then { model_instance.attribute == Money.new(1, 'AUD') }
#     end
#
#     context "When currency is null it should default to no currency" do
#       When(:initial_currency_value) { nil }
#       Then { model_instance.attribute == Money.new(1) }
#     end
#
#     context "Setting with a different currency causes an error" do
#       When(:initial_currency_value) { 'AUD' }
#       Then do
#         assert_raises(RuntimeError) { model_instance.attribute = Money.new(1_000_000, 'BTC') }
#       end
#     end
#
#     context "Setting with currency other than default currency when the parent currency is nil raises an error" do
#       When(:initial_currency_value) { nil }
#       Then do
#         assert_raises(RuntimeError) { model_instance.attribute = Money.new(1_000_000, 'BTC') }
#       end
#     end
#
#     context "Setting with the same currency as the parent object works" do
#       When(:initial_currency_value) { 'BTC' }
#       When(:an_amount_with_currency_is_set) { model_instance.attribute = Money.new(1_000_000, 'BTC') }
#       Then{ model_instance.attribute == Money.new(1_000_000, 'BTC')  }
#     end
#   end
# end
