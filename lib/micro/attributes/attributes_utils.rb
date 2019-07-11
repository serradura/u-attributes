# frozen_string_literal: true

module Micro
  module Attributes
    module AttributesUtils
      ARGUMENT_ERROR_MSG = 'argument must be a Hash'.freeze

      def self.hash_argument!(arg)
        return arg if arg.is_a?(Hash)

        raise ArgumentError, ARGUMENT_ERROR_MSG
      end

      def self.stringify_hash_keys!(arg)
        hash_argument!(arg).each_with_object({}) do |(key, val), memo|
          memo[key.to_s] = val
        end
      end
    end
  end
end
