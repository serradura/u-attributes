# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept

      module Strict
        ATTRIBUTES_REJECTED = "One or more attributes were rejected. Errors:\n".freeze

        def __call_after_attributes_assign
          return unless attributes_errors?

          raise ArgumentError, [
            ATTRIBUTES_REJECTED,
            attributes_errors.map { |key, msg| "* #{key.inspect} #{msg}" }.join("\n")
          ].join
        end
      end

    end
  end
end
