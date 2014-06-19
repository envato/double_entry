# encoding: utf-8
module DoubleEntry
  module Reporting
    include Configurable

    class Configuration
      attr_accessor :start_of_business

      def initialize #:nodoc:
        @start_of_business = Time.new(1970, 1, 1)
      end
    end

  end
end
