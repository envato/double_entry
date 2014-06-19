# encoding: utf-8
module DoubleEntry
  class BalanceCalculator

    def initialize(account, scope, from, to, at, codes)
      if account.is_a? Symbol
        @account = account.to_s
        @scope = scope ? scope.id.to_s : nil
      else
        @account = account.identifier.to_s
        @scope = account.scope_identity
      end

      @from = from
      @to = to
      @at = at
      @codes = codes
    end

    def self.calculate(account, args = {})
      codes = (args[:codes].to_a << args[:code]).compact
      calculator = BalanceCalculator.new(account, args[:scope], args[:from], args[:to], args[:at], codes)
      calculator.calculate
    end

    def calculate
      lines = Line.where(:account => account)
      lines = lines.where('created_at <= ?', at) if scope_by_created_at_before?
      lines = lines.where(:created_at, from..to) if scope_by_created_at_between?
      lines = lines.where(:code => codes) if scope_by_code?
      lines = lines.where(:scope => scope) if scope_by_scope?

      if lookup_via_created_at_range_or_code?
        # from and to or code lookups have to be done via sum
        Money.new(lines.sum(:amount))
      else
        # all other lookups can be performed with running balances
        line = lines.select("id, balance").from(lines_table_name).order('id desc').first
        line ? line.balance : Money.empty
      end
    end

  private

    attr_reader :account, :scope, :from, :to, :at, :codes

    def scope_by_created_at_before?
      !!at
    end

    def scope_by_created_at_between?
      !!(from && to) && !scope_by_created_at_before?
    end

    def scope_by_code?
      codes.present?
    end

    def scope_by_scope?
      !!scope
    end

    def lookup_via_created_at_range_or_code?
      (from && to) || codes
    end

    def use_index?
      # This is to work around a MySQL 5.1 query optimiser bug that causes the ORDER BY
      # on the query to fail in some circumstances, resulting in an old balance being
      # returned. This was biting us intermittently in spec runs.
      # See http://bugs.mysql.com/bug.php?id=51431
      Line.connection.adapter_name.match /mysql/i
    end

    def lines_table_name
      "#{Line.quoted_table_name} #{'USE INDEX (lines_scope_account_id_idx)' if use_index?}"
    end

  end
end
