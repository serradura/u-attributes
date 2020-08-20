# frozen_string_literal: true

module Micro
  module Attributes
    module Utils
      def self.stringify_hash_keys(arg)
        hash = Kind::Of.(::Hash, arg)

        return hash if hash.empty?

        if hash.respond_to?(:transform_keys)
          hash.transform_keys { |key| key.to_s }
        else
          hash.each_with_object({}) { |(key, val), memo| memo[key.to_s] = val }
        end
      end
    end
  end
end
