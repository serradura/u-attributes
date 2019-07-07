# frozen_string_literal: true

module Micro
  module Attributes
    module AttributesUtils
      ARGUMENT_ERROR_MSG = 'argument must be a Hash'

      def self.hash_argument!(arg)
        return arg if arg.is_a?(Hash)

        raise ArgumentError, ARGUMENT_ERROR_MSG
      end
    end
  end
end
