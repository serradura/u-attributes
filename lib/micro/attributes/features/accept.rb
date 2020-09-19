# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept
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

        KeepProc = -> validation_data { validation_data[0] == :accept && validation_data[1] == Proc }

        def __attribute_assign(key, initialize_value, attribute_data)
          validation_data = attribute_data[1]

          value_to_assign = FetchValueToAssign.(initialize_value, attribute_data[0], KeepProc.(validation_data))

          value = __attributes[key] = instance_variable_set("@#{key}", value_to_assign)

          __attribute_accept_or_reject(key, value, validation_data) if !validation_data.empty?
        end

        def __attribute_accept_or_reject(key, value, validation_data)
          error_msg = AcceptOrReject.call(key, value, validation_data)

          @__attributes_errors[key] = error_msg if error_msg
        end

        module AcceptOrReject
          extend self

          Context = Struct.new(:key, :value, :validation, :expected, :allow_nil, :rejection) do
            def self.with(key, value, data)
              new(key, value, data[0], data[1], data[2], data[3])
            end

            def accept?
              validation == :accept
            end

            def rejection_message(default)
              return default unless rejection || expected.respond_to?(:rejection_message)

              rejection_msg = rejection || expected.rejection_message

              return rejection_msg unless rejection_msg.is_a?(Proc)

              rejection_msg.arity == 0 ? rejection_msg.call : rejection_msg.call(key)
            end
          end

          QUESTION_MARK = '?'.freeze

          def call(key, value, validation_data)
            context = Context.with(key, value, validation_data)

            return if value.nil? && context.allow_nil

            expected = context.expected

            if expected.respond_to?(:call)
              validate_callable_with(context)
            elsif expected.is_a?(Class) || expected.is_a?(Module)
              validate_kind_of_with(context)
            elsif expected.is_a?(Symbol) && expected.to_s.end_with?(QUESTION_MARK)
              validate_predicate_with(context)
            end
          end

          private

            def validate_callable_with(context)
              expected = context.expected

              test = expected.call(context.value)

              return test ? nil : is_invalid_msg(context) if context.accept?

              is_invalid_msg(context) if test
            end

            IS_INVALID_MSG = 'is invalid'.freeze

            def is_invalid_msg(context)
              context.rejection_message(IS_INVALID_MSG)
            end

            def validate_kind_of_with(context)
              expected = context.expected

              test = context.value.kind_of?(expected)

              if context.accept?
                test ? nil : context.rejection_message("expected to be a kind of #{expected}")
              else
                context.rejection_message("expected to not be a kind of #{expected}") if test
              end
            end

            def validate_predicate_with(context)
              expected = context.expected

              test = context.value.public_send(expected)

              if context.accept?
                test ? nil : context.rejection_message("expected to be #{expected}")
              else
                context.rejection_message("expected to not be #{expected}") if test
              end
            end

          private_constant :Context, :QUESTION_MARK, :IS_INVALID_MSG
        end

        private_constant :AcceptOrReject, :KeepProc
    end
  end
end
