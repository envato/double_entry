# encoding: utf-8
require "active_support/log_subscriber"

module ActiveRecord
  module LockingExtensions
    class LogSubscriber < ActiveSupport::LogSubscriber
      def deadlock_restart(event)
        info "Deadlock causing restart"
        debug event[:exception]
      end

      def deadlock_retry(event)
        info "Deadlock causing retry"
        debug event[:exception]
      end

      def duplicate_ignore(event)
        info "Duplicate ignored"
        debug event[:exception]
      end

      def logger
        ActiveRecord::Base.logger
      end
    end
  end
end

ActiveRecord::LockingExtensions::LogSubscriber.attach_to :active_record
