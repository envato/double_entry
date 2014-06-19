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
      @codes = codes
    end


    def self.calculate(account, args = {})
      codes = (args[:codes].to_a << args[:code]).compact
      calculator = BalanceCalculator.new(account, args[:scope], args[:from], args[:to], args[:at], codes)
      calculator.calculate
    end

    def calculate
      # time based scoping
      conditions = if at
        # lookup method could use running balance, with a order by limit one clause
        # (unless it's a reporting call, i.e. account == symbol and not an instance)
        ['account = ? and created_at <= ?', account, at] # index this??
      elsif from and to
        ['account = ? and created_at >= ? and created_at <= ?', account, from, to] # index this??
      else
        # lookup method could use running balance, with a order by limit one clause
        # (unless it's a reporting call, i.e. account == symbol and not an instance)
        ['account = ?', account]
      end

      # code based scoping
      if codes.present?
        conditions[0] << ' and code in (?)' # index this??
        conditions << codes.collect { |c| c.to_s }
      end

      # account based scoping
      if scope
        conditions[0] << ' and scope = ?'
        conditions << scope

        # This is to work around a MySQL 5.1 query optimiser bug that causes the ORDER BY
        # on the query to fail in some circumstances, resulting in an old balance being
        # returned. This was biting us intermittently in spec runs.
        # See http://bugs.mysql.com/bug.php?id=51431
        if Line.connection.adapter_name.match /mysql/i
          use_index = "USE INDEX (lines_scope_account_id_idx)"
        end
      end

      if (from and to) or (codes)
        # from and to or code lookups have to be done via sum
        Money.new(Line.where(conditions).sum(:amount))
      else
        # all other lookups can be performed with running balances
        line = Line.select("id, balance").from("#{Line.quoted_table_name} #{use_index}").where(conditions).order('id desc').first
        line ? line.balance : Money.empty
      end
    end

  private

    attr_reader :account, :scope, :from, :to, :at, :codes

  end
end
