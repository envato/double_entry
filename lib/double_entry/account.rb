# encoding: utf-8
module DoubleEntry
  class Account

    # @api private
    def self.account(defined_accounts, identifier, options = {})
      account = defined_accounts.find(identifier, options[:scope].present?)
      DoubleEntry::Account::Instance.new(:account => account, :scope => options[:scope])
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
      attr_reader :account, :scope
      delegate :identifier, :scope_identifier, :scoped?, :positive_only, :to => :account

      def initialize(attributes)
        @account = attributes[:account]
        @scope = attributes[:scope]
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
        if scoped?
          [scope_identity, identifier.to_s] <=> [account.scope_identity, account.identifier.to_s]
        else
          identifier.to_s <=> account.identifier.to_s
        end
      end

      def hash
        if scoped?
          "#{scope_identity}:#{identifier}".hash
        else
          identifier.hash
        end
      end

      def to_s
        "\#{Account account: #{identifier} scope: #{scope}}"
      end

      def inspect
        to_s
      end
    end

    attr_reader :identifier, :scope_identifier, :positive_only

    def initialize(attributes)
      @identifier = attributes[:identifier]
      @scope_identifier = attributes[:scope_identifier]
      @positive_only = attributes[:positive_only]
      if identifier.length > 31
        raise AccountIdentifierTooLongError.new "account identifier '#{identifier}' is too long. Please limit it to 31 characters."
      end
    end

    def scoped?
      !!scope_identifier
    end
  end
end
