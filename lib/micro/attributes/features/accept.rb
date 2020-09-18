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

          requrmt_strategy, requrmt_expected = attribute_data[1]

          __attribute_validate(name, value, requrmt_strategy, requrmt_expected) if requrmt_strategy
        end

        def __attribute_validate(name, value, strategy, expected)
          error_msg = AcceptOrReject.call(strategy, value, expected)

          @__attributes_errors[name] = error_msg if error_msg
        end

        module AcceptOrReject
          extend self

          QUESTION_MARK = '?'.freeze

          def call(strategy, value, expected)
            is_accept = strategy == :accept

            if expected.is_a?(Class) || expected.is_a?(Module)
              validate_with_kind_of(is_accept, value, expected)
            elsif expected.is_a?(Symbol) && expected.to_s.end_with?(QUESTION_MARK)
              validate_with_predicate(is_accept, value, expected)
            end
          end

          private

            def validate_with_kind_of(is_accept, value, expected)
              test = value.kind_of?(expected)

              return test ? nil : "expected to be a kind of #{expected}" if is_accept

              "expected to not be a kind of #{expected}" if test
            end

            def validate_with_predicate(is_accept, value, expected)
              test = value.public_send(expected)

              return test ? nil : "expected to be #{expected}" if is_accept

              "expected to not be #{expected}" if test
            end
        end

        private_constant :AcceptOrReject
    end
  end
end
