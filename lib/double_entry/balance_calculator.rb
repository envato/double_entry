# encoding: utf-8
module DoubleEntry
  module BalanceCalculator
    extend self

    # Get the current or historic balance of an account.
    #
    # @param account [DoubleEntry::Account:Instance]
    # @option args :from [Time]
    # @option args :to [Time]
    # @option args :at [Time]
    # @option args :code [Symbol]
    # @option args :codes [Array<Symbol>]
    # @return [Money]
    #
    def calculate(account, args = {})
      options = Options.new(account, args)
      lines = lines(account, args)

      if options.between? || options.code?
        # from and to or code lookups have to be done via sum
        Money.new(lines.sum(:amount), account.currency)
      else
        # all other lookups can be performed with running balances
        result = lines.
                 from(lines_table_name(options)).
                 order('id DESC').
                 limit(1).
                 pluck(:balance)
        result.empty? ? Money.zero(account.currency) : Money.new(result.first, account.currency)
      end
    end

    # Get line entries of an account
    #
    # @param account [DoubleEntry::Account:Instance]
    # @option args :from [Time]
    # @option args :to [Time]
    # @option args :at [Time]
    # @option args :code [Symbol]
    # @option args :codes [Array<Symbol>]
    # @return [Money]
    #
    def lines(account, args = {})
      options = Options.new(account, args)
      relations = RelationBuilder.new(options)
      relations.build
    end

  private

    def lines_table_name(options)
      "#{Line.quoted_table_name}#{' USE INDEX (lines_scope_account_id_idx)' if force_index?(options)}"
    end

    def force_index?(options)
      # This is to work around a MySQL 5.1 query optimiser bug that causes the ORDER BY
      # on the query to fail in some circumstances, resulting in an old balance being
      # returned. This was biting us intermittently in spec runs.
      # See http://bugs.mysql.com/bug.php?id=51431
      options.scope? && Line.connection.adapter_name.match(/mysql/i)
    end

    # @api private
    class Options
      attr_reader :account, :scope, :from, :to, :at, :codes

      def initialize(account, args = {})
        @account = account.identifier.to_s
        @scope = account.scope_identity
        @codes = (args[:codes].to_a << args[:code]).compact
        @from = args[:from]
        @to = args[:to]
        @at = args[:at]
      end

      def at?
        !!at
      end

      def between?
        !!(from && to && !at?)
      end

      def code?
        codes.present?
      end

      def scope?
        !!scope
      end
    end

    # @api private
    class RelationBuilder
      attr_reader :options
      delegate :account, :scope, :scope?, :from, :to, :between?, :at, :at?, :codes, :code?, to: :options

      def initialize(options)
        @options = options
      end

      def build
        lines = Line.where(account: account)
        lines = lines.where('created_at <= ?', at) if at?
        lines = lines.where(created_at: from..to) if between?
        lines = lines.where(code: codes) if code?
        lines = lines.where(scope: scope) if scope?
        lines.readonly
      end
    end
  end
end
