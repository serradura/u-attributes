# frozen_string_literal: true

module Micro
  module Attributes
    module Differ
      class Changes
        attr_reader :from, :to, :differences

        def initialize(from:, to:)
          @from, @to = from, to
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
            raise ArgumentError, 'pass the attribute name with the :from and :to values'
          elsif from.nil? && to.nil?
            differences.has_key?(name.to_s)
          else
            key = name.to_s
            @from_attributes[key] == from && @to_attributes[key] == to
          end
        end

        private

        def diff(from_attrs, to_attrs)
          @to_attributes = to_attrs.freeze
          @from_attributes = from_attrs.freeze
          @from_attributes.each_with_object({}) do |(from_key, from_val), acc|
            to_value = @to_attributes[from_key]
            acc[from_key] = to_value if from_val != to_value
          end
        end
      end
      private_constant :Changes

      def diff_attributes(to)
        return Changes.new(from: self, to: to) if to.is_a?(::Micro::Attributes)

        raise ArgumentError, "#{to.inspect} must be Micro::Attributes"
      end
    end
  end
end
