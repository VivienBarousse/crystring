module Crystring
  module Types
    class Base
      def initialize(str)
        @str = str
        @variables = {}
      end

      def call_method(name, args)
        if self.class.get_method(name)
          self.class.get_method(name).invoke(args)
        elsif self.class.base_class
          self.class.base_class.get_method(name).invoke(args)
        else
          raise "Unknown method #{name}"
        end
      end

      def self.call_method(name, args)
        raise "Unknown method #{name}" unless name == "new"
        raise "Invalid number of arguments #{args.count}, expected 1" unless args.count == 1
        new(args.first.to_s)
      end

      def self.base_class(base_class = nil)
        if base_class
          @base_class = base_class
        else
          @base_class
        end
      end

      def self.def_method(name, function)
        @methods ||= {}
        @methods[name] = function
      end

      def self.get_method(name)
        @methods ||= {}
        @methods[name]
      end

      def to_s
        @str.to_s
      end

      def ==(other)
        self.to_s == other.to_s
      end

      def variable_exists?(name)
        return true if name == "self"
        @variables.has_key?(name)
      end

      def get_variable(name)
        return @str if name == "self"
        @variables[name]
      end

      def set_variable(name, value)
        raise "Can't set `self`" if name == str
        @variables[name] = value
      end
    end
  end
end

