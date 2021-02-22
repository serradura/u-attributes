# frozen_string_literal: true

module Micro::Attributes::Utils

  module Hashes
    extend self

    def stringify_keys(arg)
      hash = Kind::Hash[arg]

      return hash if hash.empty?
      return hash.transform_keys(&:to_s) if hash.respond_to?(:transform_keys)

      hash.each_with_object({}) { |(key, val), memo| memo[key.to_s] = val }
    end

    def symbolize_keys(arg)
      hash = Kind::Hash[arg]

      return hash if hash.empty?
      return hash.transform_keys(&:to_sym) if hash.respond_to?(:transform_keys)

      hash.each_with_object({}) { |(key, val), memo| memo[key.to_sym] = val }
    end

    def keys_as(type, hash)
      return Kind::Hash[hash] unless type

      return symbolize_keys(hash) if type == Symbol || type == :symbol
      return stringify_keys(hash) if type == String || type == :string

      raise ArgumentError, 'argument must be one of these values: :symbol, :string, Symbol, String'.freeze
    end

    def assoc(hash, key)
      value = hash[key.to_s]

      value.nil? ? hash[key.to_sym] : value
    end
  end

  module ExtractAttribute
    def self.call(object, key:)
      return object.public_send(key) if object.respond_to?(key)

      Hashes.assoc(object, key) if object.respond_to?(:[])
    end

    def self.from(object, keys:)
      Kind::Array[keys].each_with_object({}) do |key, memo|
        memo[key] = call(object, key: key)
      end
    end
  end

end
