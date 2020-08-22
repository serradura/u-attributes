# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Initialize
      module Strict
        MISSING_KEYWORD = 'missing keyword'.freeze
        MISSING_KEYWORDS = 'missing keywords'.freeze

        protected def attributes=(arg)
          hash = Utils.stringify_hash_keys(arg)

          __attributes_missing!(hash)

          __attributes_assign(hash)
        end

        private def __attributes_missing!(hash)
          required_keys = self.class.__attribute_names_without_default__

          return if required_keys.empty?

          missing_keys = required_keys.map { |name| ":#{name}" if !hash.key?(name) }
          missing_keys.compact!

          return if missing_keys.empty?

          label = missing_keys.size == 1 ? MISSING_KEYWORD : MISSING_KEYWORDS

          raise ArgumentError, "#{label}: #{missing_keys.join(', ')}"
        end

        private_constant :MISSING_KEYWORD, :MISSING_KEYWORDS
      end
    end
  end
end
