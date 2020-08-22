# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Initialize
      module Strict
        MISSING_KEYWORD = 'missing keyword'.freeze
        MISSING_KEYWORDS = 'missing keywords'.freeze

        protected def attributes=(arg)
          arg_hash = Utils.stringify_hash_keys(arg)
          att_data = self.class.__attributes_data__

          attributes_missing!(ref: att_data, arg: arg_hash)

          __attributes_assign(arg_hash, att_data)
        end

        private def attributes_missing!(ref:, arg:)
          missing_keys = attributes_missing(ref, arg)

          return if missing_keys.empty?

          label = missing_keys.size == 1 ? MISSING_KEYWORD : MISSING_KEYWORDS

          raise ArgumentError, "#{label}: #{missing_keys.join(', ')}"
        end

        private def attributes_missing(ref, arg)
          ref.each_with_object([]) do |(key, val), memo|
            memo << ":#{key}" if val.nil? && !arg.has_key?(key)
          end
        end

        private_constant :MISSING_KEYWORD, :MISSING_KEYWORDS
      end
    end
  end
end
