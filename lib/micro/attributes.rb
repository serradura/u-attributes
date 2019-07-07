# frozen_string_literal: true

require "micro/attributes/version"
require "micro/attributes/utils"
require "micro/attributes/macros"
require "micro/attributes/to_initialize"

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
      @to_initialize ||= ::Micro::Attributes.const_get(:ToInitialize)
    end

    def attributes=(arg)
      self.class.attributes_data(Utils.hash_argument!(arg)).each do |name, value|
        instance_variable_set("@#{name}", value) if attribute?(name)
      end
    end
    protected :attributes=

    def attributes
      state = self.class.attributes.each_with_object({}) do |name, memo|
        memo[name] = public_send(name) if respond_to?(name)
      end

      self.class.attributes_data(state)
    end

    def attribute?(name)
      self.class.attribute?(name)
    end
  end
end
