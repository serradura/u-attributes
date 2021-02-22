# frozen_string_literal: true

module Micro::Attributes
  module Diff
    class Changes
      FROM_TO_SYM = [:from, :to].freeze
      FROM_TO_STR = ['from'.freeze, 'to'.freeze].freeze
      FROM_TO_ERROR = 'pass the attribute name with the :from and :to values'.freeze

      attr_reader :from, :to, :differences

      def initialize(from:, to:)
        @from_class = from.class

        @from, @to = from, Kind.of(@from_class, to)

        @from_key, @to_key =
          @from_class.attributes_access == :symbol ? FROM_TO_SYM : FROM_TO_STR

        @differences = diff(from.attributes, to.attributes).freeze
      end

      def empty?
        @differences.empty?
      end
      alias_method :blank?, :empty?

      def present?
        !empty?
      end

      def changed?(name = nil, from: nil, to: nil)
        if name.nil?
          return present? if from.nil? && to.nil?

          raise ArgumentError, FROM_TO_ERROR
        elsif from.nil? && to.nil?
          differences.has_key?(key_transform(name))
        else
          result = @differences[key_transform(name)]
          result ? result[@from_key] == from && result[@to_key] == to : false
        end
      end

      private

        def key_transform(key)
          @from_class.__attribute_key_transform__(key)
        end

        def diff(from_attributes, to_attributes)
          @from_attributes, @to_attributes = from_attributes, to_attributes

          @from_attributes.each_with_object({}) do |(from_key, from_val), acc|
            to_value = @to_attributes[from_key]

            acc[from_key] = {@from_key => from_val, @to_key => to_value}.freeze if from_val != to_value
          end
        end

      private_constant :FROM_TO_SYM, :FROM_TO_STR, :FROM_TO_ERROR
    end
  end
end
