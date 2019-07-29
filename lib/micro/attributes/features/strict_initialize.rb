# frozen_string_literal: true

module Micro::Attributes
  module Features
    module StrictInitialize
      MISSING_KEYWORD = 'missing keyword'.freeze
      MISSING_KEYWORDS = 'missing keywords'.freeze

      def self.included(base)
        base.send(:include, ::Micro::Attributes::Features::Initialize)
      end

      protected def attributes=(arg)
        arg_hash = AttributesUtils.stringify_hash_keys!(arg)
        att_data = self.class.attributes_data({})

        attributes_missing!(ref: att_data, arg: arg_hash)

        att_data.merge(arg_hash).each { |name, value| __attribute_set(name, value) }

        __attributes.freeze
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
