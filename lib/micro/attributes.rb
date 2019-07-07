# frozen_string_literal: true

require "micro/attributes/version"
require "micro/attributes/utils"
require "micro/attributes/macros"

module Micro
  module Attributes
    def self.included(base)
      base.extend Macros

      base.class_eval do
        private_class_method :__attribute
        private_class_method :__attributes
        private_class_method :__attribute_data
        private_class_method :__attribute_data!
        private_class_method :__attributes_data
      end

      def base.inherited(subclass)
        self.attributes_data({}).each do |name, value|
          subclass.attribute(value.nil? ? name : {name => value})
        end

        subclass.extend Macros.const_get(:ForSubclasses)
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
      self.class.attributes_data(Utils.hash_argument!(arg)).each do |name, value|
        instance_variable_set("@#{name}", value) if attribute?(name)
      end
    end

    def attributes
      state = self.class.attributes.each_with_object({}) do |name, memo|
        memo[name] = public_send(name) if respond_to?(name)
      end

      self.class.attributes_data(state)
    end

    protected :attributes=
  end
end
