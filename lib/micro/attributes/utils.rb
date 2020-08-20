# frozen_string_literal: true

module Micro
  module Attributes
    module Utils
      def self.stringify_hash_keys(arg)
        return arg if arg.empty?

        if arg.respond_to?(:transform_keys)
          arg.transform_keys { |key| key.to_s }
        else
          arg.each_with_object({}) { |(key, val), memo| memo[key.to_s] = val }
        end
      end

      def self.stringify_hash_keys!(arg)
        stringify_hash_keys(Kind::Of.(::Hash, arg))
      end
    end

    private_constant :Utils
  end
end
