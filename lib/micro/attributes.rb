# frozen_string_literal: true

require 'kind'

module Micro
  module Attributes
    require 'micro/attributes/version'
    require 'micro/attributes/utils'
    require 'micro/attributes/diff'
    require 'micro/attributes/macros'
    require 'micro/attributes/features'

    def self.included(base)
      base.extend(::Micro::Attributes.const_get(:Macros))

      base.class_eval do
        private_class_method :__attributes_data, :__attributes
        private_class_method :__attribute_set, :__attribute_reader
      end

      def base.inherited(subclass)
        subclass.__inherited_attributes_set__(self.__attributes_data__({}))
        subclass.extend ::Micro::Attributes.const_get('Macros::ForSubclasses'.freeze)
      end
    end

    def self.without(*names)
      Features.without(names)
    end

    def self.with(*names)
      Features.with(names)
    end

    def self.with_all_features
      Features.all
    end

    protected def attributes=(arg)
      self.class
          .__attributes_data__(Kind::Of.(::Hash, arg))
          .each { |name, value| __attribute_set(name, value) }

      __attributes.freeze
    end

    def attributes(*names)
      return __attributes if names.empty?

      names.each_with_object({}) do |name, memo|
        memo[name] = attribute(name) if attribute?(name)
      end
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

    private

      def __attributes
        @__attributes ||= {}
      end

      def __attribute_set(name, value)
        __attributes[name] = instance_variable_set("@#{name}", value) if attribute?(name)
      end
  end
end
