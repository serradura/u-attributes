# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept

      module ClassMethods
      end

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      def attributes_errors
        @__attributes_errors
      end

      def rejected_attributes
        @rejected_attributes ||= attributes_errors.keys
      end

      def accepted_attributes
        @accepted_attributes ||= defined_attributes - rejected_attributes
      end

      def attributes_errors?
        !@__attributes_errors.empty?
      end

      def rejected_attributes?
        attributes_errors?
      end

      def accepted_attributes?
        !rejected_attributes?
      end

      private

        def __call_before_attributes_assign
          @__attributes_errors = {}
        end

        def __attribute_assign(name, initialize_value, attribute_data)
          value_to_assign = FetchValueToAssign.(initialize_value, attribute_data[0])

          value = __attributes[name] = instance_variable_set("@#{name}", value_to_assign)

          validation, expected = attribute_data[1]

          __attribute_accept_or_reject(name, value, expected, validation) if validation
        end

        def __attribute_accept_or_reject(name, value, expected, validation)
          error_msg = AcceptOrReject.call(value, expected, validation)

          @__attributes_errors[name] = error_msg if error_msg
        end

        module AcceptOrReject
          extend self

          QUESTION_MARK = '?'.freeze

          def call(value, expected, validation)
            if expected.is_a?(Class) || expected.is_a?(Module)
              validate_kind_of_with(expected, value, validation)
            elsif expected.is_a?(Symbol) && expected.to_s.end_with?(QUESTION_MARK)
              validate_predicate_with(expected, value, validation)
            end
          end

          private

            def accept?(validation)
              validation == :accept
            end

            def validate_kind_of_with(expected, value, validation)
              test = value.kind_of?(expected)

              return test ? nil : "expected to be a kind of #{expected}" if accept?(validation)

              "expected to not be a kind of #{expected}" if test
            end

            def validate_predicate_with(expected, value, validation)
              test = value.public_send(expected)

              return test ? nil : "expected to be #{expected}" if accept?(validation)

              "expected to not be #{expected}" if test
            end
        end

        private_constant :AcceptOrReject
    end
  end
end
