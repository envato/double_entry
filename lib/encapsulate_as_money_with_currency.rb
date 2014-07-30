# encoding: utf-8
require "money"

module EncapsulateAsMoneyWithCurrency
  def encapsulate_as_money_and_currency(*attributes)
    options = extract_options(attributes)
    attributes.each do |attribute|
      encapsulate_attribute_as_money_with_currency(attribute, options[:preserve_nil])
    end
  end

  private

  def encapsulate_attribute_as_money_with_currency(attribute, preserve_nil = true)
    if preserve_nil
      define_method attribute do
        Money.new(super(), currency) if super()
      end
    else
      define_method attribute do
        Money.new((super() || 0), currency)
      end
    end

    define_method "#{attribute}=" do |money|
      super(money && money.fractional)
    end
  end

  def extract_options(args)
    args.last.is_a?(Hash) ? args.pop : {}
  end
end
