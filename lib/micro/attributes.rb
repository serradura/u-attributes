# frozen_string_literal: true

require "micro/attributes/version"
require "micro/attributes/attributes_utils"
require "micro/attributes/macros"
require "micro/attributes/to_initialize"

module Micro
  module Attributes
    def self.included(base)
      base.extend(::Micro::Attributes.const_get(:Macros))

      base.class_eval do
        private_class_method :__attributes_data, :__attributes
        private_class_method :__attributes_def, :__attributes_set
        private_class_method :__attribute_reader, :__attribute_set
      end

      def base.inherited(subclass)
        subclass.attributes(self.attributes_data({}))
        subclass.extend ::Micro::Attributes.const_get('Macros::ForSubclasses')
      end
    end

    def self.to_initialize
      @to_initialize ||= ::Micro::Attributes.const_get(:ToInitialize)
    end

    def attributes=(arg)
      self.class.attributes_data(AttributesUtils.hash_argument!(arg)).each do |name, value|
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

    def attribute(name)
      return unless attribute?(name)

      value = public_send(name)

      block_given? ? yield(value) : value
    end

    def attribute!(name, &block)
      attribute(name) { |name| return block ? block[name] : name }

      raise NameError, "undefined attribute `#{name}"
    end
  end
end
