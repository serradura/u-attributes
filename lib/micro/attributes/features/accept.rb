# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept
      def attributes_errors
        @__attributes_errors
      end

      def attributes_errors?
        !@__attributes_errors.empty?
      end

      def rejected_attributes
        @__rejected_attributes ||= attributes_errors.keys
      end

      def accepted_attributes
        @__accepted_attributes ||= defined_attributes - rejected_attributes
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
          context = Context.with(key, value, validation_data)

          error_msg = context.rejection_message(Validate.call(context))

          @__attributes_errors[key] = error_msg if error_msg
        end

        Context = Struct.new(:key, :value, :validation, :expected, :allow_nil, :rejection) do
          def self.with(key, value, data)
            new(key, value, data[0], data[1], data[2], data[3])
          end

          def allow_nil?
            allow_nil && value.nil?
          end

          def accept?
            validation == :accept
          end

          def rejection_message(default_msg)
            return unless default_msg

            return default_msg unless rejection || expected.respond_to?(:rejection_message)

            rejection_msg = rejection || expected.rejection_message

            return rejection_msg unless rejection_msg.is_a?(Proc)

            rejection_msg.arity == 0 ? rejection_msg.call : rejection_msg.call(key)
          end
        end

        module Validate
          module Callable
            MESSAGE = 'is invalid'.freeze

            def self.call?(exp); exp.respond_to?(:call); end
            def self.call(exp, val); exp.call(val); end
            def self.accept_failed(_exp); MESSAGE; end
            def self.reject_failed(_exp); MESSAGE; end
          end

          module KindOf
            def self.call?(exp); exp.is_a?(Class) || exp.is_a?(Module); end
            def self.call(exp, val); val.kind_of?(exp); end
            def self.accept_failed(exp); "expected to be a kind of #{exp}"; end
            def self.reject_failed(exp); "expected to not be a kind of #{exp}"; end
          end

          module Predicate
            QUESTION_MARK = '?'.freeze

            def self.call?(exp); exp.is_a?(Symbol) && exp.to_s.end_with?(QUESTION_MARK); end
            def self.call(exp, val); val.public_send(exp); end
            def self.accept_failed(exp); "expected to be #{exp}"; end
            def self.reject_failed(exp); "expected to not be #{exp}"; end
          end

          def self.with(expected)
            return Callable if Callable.call?(expected)
            return KindOf if KindOf.call?(expected)
            return Predicate if Predicate.call?(expected)
          end

          def self.call(context)
            return if context.allow_nil?

            validate = self.with(expected = context.expected)

            return unless validate

            truthy = validate.call(expected, context.value)

            return truthy ? nil : validate.accept_failed(expected) if context.accept?

            validate.reject_failed(expected) if truthy
          end
        end

        private_constant :KeepProc, :Context, :Validate
    end
  end
end
