module Crystring
  module Types
    class Integer
      def initialize(str)
        @str = str
        @variables = {}
      end

      def call_method(name, args)
        raise "Unknown method #{name}" unless self.class.get_method(name)
        self.class.get_method(name).invoke(args)
      end

      def self.call_method(name, args)
        raise "Unknown method #{name}" unless name == "new"
        raise "Invalid number of arguments #{args.count}, expected 1" unless args.count == 1
        new(args.first.to_s)
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
        @str
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


