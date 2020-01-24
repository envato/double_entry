# encoding: utf-8
module DoubleEntry
  # Make configuring a module or a class simple.
  #
  #   class MyClass
  #     include Configurable
  #
  #     class Configuration
  #       attr_accessor :my_config_option
  #
  #       def initialize #:nodoc:
  #         @my_config_option = "default value"
  #       end
  #     end
  #   end
  #
  # Then in an initializer (or environments/*.rb) do:
  #
  #   MyClass.configure do |config|
  #     config.my_config_option = "custom value"
  #   end
  #
  # And inside methods in your class you can access your config:
  #
  #   class MyClass
  #     def my_method
  #       puts configuration.my_config_option
  #     end
  #   end
  #
  # This is all based on this article:
  #
  #     http://robots.thoughtbot.com/post/344833329/mygem-configure-block
  #
  module Configurable
    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods #:nodoc:
      def configuration
        @configuration ||= self::Configuration.new
      end
      alias config configuration

      def configure
        yield(configuration)
      end
    end
  end
end
