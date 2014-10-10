# encoding: utf-8
module DoubleEntry
  class Account

    # @api private
    def self.account(defined_accounts, identifier, options = {})
      account = defined_accounts.find(identifier, options[:scope].present?)
      DoubleEntry::Account::Instance.new(:account => account, :scope => options[:scope])
    end

    # @api private
    def self.currency(defined_accounts, account)
      code = account.is_a?(Symbol) ? account : account.identifier

      found_account = defined_accounts.detect do |account|
        account.identifier == code
      end

      found_account.currency
    end

    # @api private
    class Set < Array
      def define(attributes)
        self << Account.new(attributes)
      end

      def find(identifier, scoped)
        account = detect do |account|
          account.identifier == identifier && account.scoped? == scoped
        end
        raise UnknownAccount.new("account: #{identifier} scoped?: #{scoped}") unless account
        return account
      end

      def <<(account)
        if any? { |a| a.identifier == account.identifier }
          raise DuplicateAccount.new
        else
          super(account)
        end
      end

      def active_record_scope_identifier(active_record_class)
        ActiveRecordScopeFactory.new(active_record_class).scope_identifier
      end
    end

    class ActiveRecordScopeFactory
      def initialize(active_record_class)
        @active_record_class = active_record_class
      end

      def scope_identifier
        ->(value) { value.is_a?(@active_record_class) ? value.id : value }
      end
    end

    class Instance
      attr_accessor :account, :scope
      delegate :identifier, :scope_identifier, :scoped?, :positive_only, :currency, :to => :account

      def initialize(attributes)
        attributes.each { |name, value| send("#{name}=", value) }
      end

      def scope_identity
        scope_identifier.call(scope).to_s if scoped?
      end

      # Get the current or historic balance of this account.
      #
      # @option options :from [Time]
      # @option options :to [Time]
      # @option options :at [Time]
      # @option options :code [Symbol]
      # @option options :codes [Array<Symbol>]
      # @return [Money]
      #
      def balance(options = {})
        BalanceCalculator.calculate(self, options)
      end

      include Comparable

      def ==(other)
        other.is_a?(self.class) && identifier == other.identifier && scope_identity == other.scope_identity
      end

      def eql?(other)
        self == other
      end

      def <=>(account)
        [scope_identity.to_s, identifier.to_s] <=> [account.scope_identity.to_s, account.identifier.to_s]
      end

      def hash
        if scoped?
          "#{scope_identity}:#{identifier}".hash
        else
          identifier.hash
        end
      end

      def to_s
        "\#{Account account: #{identifier} scope: #{scope} currency: #{currency}}"
      end

      def inspect
        to_s
      end
    end

    attr_accessor :identifier, :scope_identifier, :positive_only, :currency

    def initialize(attributes)
      attributes.each { |name, value| send("#{name}=", value) }
      self.currency ||= Money.default_currency
    end

    def scoped?
      !!scope_identifier
    end
  end
end
