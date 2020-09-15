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
        private_class_method :__attributes, :__attribute_reader
        private_class_method :__attribute_assign, :__attributes_data_to_assign
        private_class_method :__attributes_required_add, :__attributes_data_to_assign
      end

      def base.inherited(subclass)
        subclass.__attributes_set_after_inherit__(self.__attributes_data__)

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

    def defined_attributes
      @defined_attributes ||= self.class.attributes
    end

    def attributes(*names)
      return __attributes if names.empty?

      options = names.last.is_a?(Hash) ? names.pop : Kind::Empty::HASH

      names.flatten!

      without_option = Array(options.fetch(:without, Kind::Empty::ARRAY))

      keys = names.empty? ? defined_attributes - without_option.map { |value| __attribute_key(value) } : names - without_option

      data = keys.each_with_object({}) { |key, memo| memo[key] = attribute(key) if attribute?(key) }

      with_option = Array(options.fetch(:with, Kind::Empty::ARRAY))

      unless with_option.empty?
        extra = with_option.each_with_object({}) { |key, memo| memo[__attribute_key(key)] = public_send(key) }

        data.merge!(extra)
      end

      Utils::Hashes.keys_as(options[:keys_as], data)
    end

    protected

      def attributes=(arg)
        hash = self.class.__attribute_keys_transform__(arg)

        __attributes_missing!(hash)

        __call_before_attributes_assign
        __attributes_assign(hash)
        __call_after_attributes_assign

        __attributes
      end

    private

      def __call_before_attributes_assign; end
      def __call_after_attributes_assign; end

      def extract_attributes_from(other)
        Utils::ExtractAttribute.from(other, keys: defined_attributes)
      end

      def __attribute_key(value)
        self.class.__attribute_key_transform__(value)
      end

      def __attributes
        @__attributes ||= {}
      end

      FetchValueToAssign = -> (value, default) do
        if default.is_a?(Proc)
          default.arity > 0 ? default.call(value) : default.call
        else
          value.nil? ? default : value
        end
      end

      def __attributes_assign(hash)
        self.class.__attributes_data__.each do |name, attribute_data|
          __attribute_assign(name, hash[name], attribute_data) if attribute?(name)
        end

        __attributes.freeze
      end

      def __attribute_assign(name, initialize_value, attribute_data)
        value_to_assign = FetchValueToAssign.(initialize_value, attribute_data[0])

        __attributes[name] = instance_variable_set("@#{name}", value_to_assign)
      end

      MISSING_KEYWORD = 'missing keyword'.freeze
      MISSING_KEYWORDS = 'missing keywords'.freeze

      def __attributes_missing!(hash)
        required_keys = self.class.__attributes_required__

        return if required_keys.empty?

        missing_keys = required_keys.map { |name| ":#{name}" if !hash.key?(name) }
        missing_keys.compact!

        return if missing_keys.empty?

        label = missing_keys.size == 1 ? MISSING_KEYWORD : MISSING_KEYWORDS

        raise ArgumentError, "#{label}: #{missing_keys.join(', ')}"
      end

      private_constant :FetchValueToAssign, :MISSING_KEYWORD, :MISSING_KEYWORDS
  end
end
