# frozen_string_literal: true

module Micro
  module Attributes
    module Hash
      def self.with_string_keys!(arg)
        Kind::Of::Hash(arg).each_with_object({}) do |(key, val), memo|
          memo[key.to_s] = val
        end
      end
    end
  end
end
