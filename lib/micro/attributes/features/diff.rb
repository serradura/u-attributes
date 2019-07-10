# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Diff
      class Changes
        attr_reader :from, :to, :differences

        def initialize(from:, to:)
          raise ArgumentError, "expected an instance of #{from.class}" unless to.is_a?(from.class)
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

        def diff(from_attributes, to_attributes)
          @to_attributes = to_attributes
          @from_attributes = from_attributes
          @from_attributes.each_with_object({}) do |(from_key, from_val), acc|
            to_value = @to_attributes[from_key]
            acc[from_key] = to_value if from_val != to_value
          end
        end
      end
      private_constant :Changes

      def diff_attributes(to)
        return Changes.new(from: self, to: to) if to.is_a?(::Micro::Attributes)
        raise ArgumentError, "#{to.inspect} must implement Micro::Attributes"
      end
    end
  end
end
