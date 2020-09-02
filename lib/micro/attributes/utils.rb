# frozen_string_literal: true

module Micro::Attributes
  module Utils
    module Hashes
      def self.stringify_keys(arg)
        hash = Kind::Of.(::Hash, arg)

        return hash if hash.empty?
        return hash.transform_keys(&:to_s) if hash.respond_to?(:transform_keys)

        hash.each_with_object({}) { |(key, val), memo| memo[key.to_s] = val }
      end

      def self.get(hash, key)
        value = hash[key.to_s]

        value.nil? ? hash[key.to_sym] : value
      end
    end

    module ExtractAttribute
      def self.call(object, key:)
        return object.public_send(key) if object.respond_to?(key)

        Hashes.get(object, key) if object.respond_to?(:[])
      end

      def self.from(object, keys:)
        Kind::Of.(::Array, keys).each_with_object({}) do |key, memo|
          memo[key] = call(object, key: key)
        end
      end
    end
  end
end
