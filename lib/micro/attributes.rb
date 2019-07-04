# frozen_string_literal: true

require "micro/attributes/version"
require "micro/attributes/macros"

module Micro
  module Attributes
    def self.included(base)
      base.extend Macros

      base.class_eval do
        private_class_method :__attribute
        private_class_method :__attributes
        private_class_method :__attribute_data
        private_class_method :__attributes_data
      end

      def base.inherited(subclass)
        self.attributes_data({}) do |data|
          data.each { |k, v| subclass.attribute(v.nil? ? k : {k => v}) }
        end
      end
    end

    def self.to_initialize
      @to_initialize ||= Module.new do
        def self.included(base)
          base.send(:include, Micro::Attributes)

          base.class_eval(<<-RUBY)
            def initialize(arg)
              self.attributes = arg
            end

            def with_attribute(key, val)
              self.class.new(attributes.merge(key => val))
            end

            def with_attributes(arg)
              self.class.new(attributes.merge(arg))
            end
          RUBY
        end
      end
    end

    def attribute?(name)
      self.class.attribute?(name)
    end

    def attributes=(arg)
      raise ArgumentError, 'argument must be a Hash' unless arg.is_a?(Hash)

      self.class.attributes_data(arg) do |data|
        data.each do |name, value|
          instance_variable_set("@#{name}", data[name]) if attribute?(name)
        end
      end
    end

    def attributes
      state =
        self.class.attributes.each_with_object({}) do |name, memo|
          if instance_variable_defined?(iv_name = "@#{name}")
            memo[name] = instance_variable_get(iv_name)
          end
        end

      self.class.attributes_data(state) { |data| data }
    end

    protected :attributes=
  end
end
