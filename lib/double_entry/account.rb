# encoding: utf-8
require 'forwardable'

module DoubleEntry
  class Account
    class << self
      attr_writer :accounts, :scope_identifier_max_length, :account_identifier_max_length

      # @api private
      def accounts
        @accounts ||= Set.new
      end

      # @api private
      def scope_identifier_max_length
        @scope_identifier_max_length ||= 23
      end

      # @api private
      def account_identifier_max_length
        @account_identifier_max_length ||= 31
      end

      # @api private
      def account(identifier, options = {})
        account = accounts.find(identifier, (options[:scope].present? || options[:scope_identity].present?))
        Instance.new(:account => account, :scope => options[:scope], :scope_identity => options[:scope_identity])
      end

      # @api private
      def currency(identifier)
        accounts.find_without_scope(identifier).try(:currency)
      end
    end

    # @api private
    class Set
      extend Forwardable

      delegate [:each, :map] => :all

      def define(attributes)
        Account.new(attributes).tap do |account|
          if find_without_scope(account.identifier)
            fail DuplicateAccount
          else
            backing_collection[account.identifier] = account
          end
        end
      end

      def find(identifier, scoped)
        found_account = find_without_scope(identifier)

        if found_account && found_account.scoped? == scoped
          found_account
        else
          fail UnknownAccount, "account: #{identifier} scoped?: #{scoped}"
        end
      end

      def find_without_scope(identifier)
        backing_collection[identifier]
      end

      def active_record_scope_identifier(active_record_class)
        ActiveRecordScopeFactory.new(active_record_class).scope_identifier
      end

      def all
        backing_collection.values
      end

    private

      def backing_collection
        @backing_collection ||= Hash.new
      end
    end

    class ActiveRecordScopeFactory
      def initialize(active_record_class)
        @active_record_class = active_record_class
      end

      def scope_identifier
        lambda do |value|
          case value
          when value.is_a?(@active_record_class)
            value.id
          when String, Integer
            value
          else
            fail AccountScopeMismatchError, "Expected instance of `#{@active_record_class}`, received instance of `#{value.class}`"
          end
        end
      end
    end

    class Instance
      attr_reader :account, :scope
      delegate :identifier, :scope_identifier, :scoped?, :positive_only, :negative_only, :currency, :to => :account

      def initialize(args)
        @account = args[:account]
        @scope = args[:scope]
        @scope_identity = args[:scope_identity]
        ensure_scope_is_valid
      end

      def scope_identity
        @scope_identity || call_scope_identifier
      end

      def call_scope_identifier
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

      def <=>(other)
        [scope_identity.to_s, identifier.to_s] <=> [other.scope_identity.to_s, other.identifier.to_s]
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

    private

      def ensure_scope_is_valid
        identity = scope_identity
        if identity && identity.length > Account.scope_identifier_max_length
          fail ScopeIdentifierTooLongError,
               "scope identifier '#{identity}' is too long. Please limit it to #{Account.scope_identifier_max_length} characters."
        end
      end
    end

    attr_reader :identifier, :scope_identifier, :positive_only, :negative_only, :currency

    def initialize(args)
      @identifier = args[:identifier]
      @scope_identifier = args[:scope_identifier]
      @positive_only = args[:positive_only]
      @negative_only = args[:negative_only]
      @currency = args[:currency] || Money.default_currency
      if identifier.length > Account.account_identifier_max_length
        fail AccountIdentifierTooLongError,
             "account identifier '#{identifier}' is too long. Please limit it to #{Account.account_identifier_max_length} characters."
      end
    end

    def scoped?
      !!scope_identifier
    end
  end
end
