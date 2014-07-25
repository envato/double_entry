# encoding: utf-8
require "money"

module EncapsulateAsMoney
  def encapsulate_as_money(*attributes)
    options = extract_options(attributes)
    attributes.each do |attribute|
      encapsulate_attribute_as_money(attribute, options[:preserve_nil])
    end
  end

private

  def encapsulate_attribute_as_money(attribute, preserve_nil = true)
    if preserve_nil
      define_method attribute do
        if respond_to?(:currency) && currency
          Money.new(super(), currency) if super()
        else
          Money.new(super()) if super()
        end
      end
    else
      define_method attribute do
        if respond_to?(:currency) && currency
          Money.new((super() || 0), currency)
        else
          Money.new(super() || 0)
        end
      end
    end

    define_method "#{attribute}=" do |money|
      if respond_to?(:currency) && currency
        raise RuntimeError.new("Currency Missmatch") if money.currency != currency
      elsif money.currency != Money.default_currency
        raise RuntimeError.new("Currency Missmatch")
      end
      super(money && money.fractional)
    end
  end

  def extract_options(args)
    args.last.is_a?(Hash) ? args.pop : {}
  end
end
