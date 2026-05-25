# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept

      module Strict
        ATTRIBUTES_REJECTED = "One or more attributes were rejected. Errors:\n".freeze
        HIDDEN_FAILURE_LINE = "* (a private or protected attribute failed validation)".freeze

        def __call_after_attributes_assign
          return unless attributes_errors? || @__hidden_validation_failed

          __raise_error_if_found_attributes_errors
        end

        def __raise_error_if_found_attributes_errors
          parts = [ATTRIBUTES_REJECTED]

          if attributes_errors?
            parts << attributes_errors.map { |key, msg| "* #{key.inspect} #{msg}" }.join("\n")
          end

          # Hidden-failure note keeps strict's fail-fast contract for
          # `private:` / `protected:` attributes without leaking their
          # names through the raise message.
          if @__hidden_validation_failed
            parts << "\n" unless parts.last.end_with?("\n")
            parts << HIDDEN_FAILURE_LINE
          end

          raise ArgumentError, parts.join
        end
      end

    end
  end
end
