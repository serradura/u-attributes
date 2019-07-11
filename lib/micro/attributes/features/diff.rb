# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Diff
      class Changes
        TO = 'to'.freeze
        FROM = 'from'.freeze
        FROM_TO_ERROR = 'pass the attribute name with the :from and :to values'.freeze

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
            raise ArgumentError, FROM_TO_ERROR
          elsif from.nil? && to.nil?
            differences.has_key?(name.to_s)
          else
            result = @differences[name.to_s]
            result ? result[FROM] == from && result[TO] == to : false
          end
        end

        private

        def diff(from_attributes, to_attributes)
          @from_attributes, @to_attributes = from_attributes, to_attributes
          @from_attributes.each_with_object({}) do |(from_key, from_val), acc|
            to_value = @to_attributes[from_key]
            acc[from_key] = {FROM => from_val, TO => to_value}.freeze if from_val != to_value
          end
        end

        private_constant :TO, :FROM, :FROM_TO_ERROR
      end

      def diff_attributes(to)
        return Changes.new(from: self, to: to) if to.is_a?(::Micro::Attributes)
        raise ArgumentError, "#{to.inspect} must implement Micro::Attributes"
      end

      private_constant :Changes
    end
  end
end
