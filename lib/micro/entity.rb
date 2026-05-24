# frozen_string_literal: true

require 'micro/attributes'

module Micro
  class Entity
    include ::Micro::Attributes.with(:initialize, :accept, :diff)

    class << self
      def attribute(name, options = ::Kind::Empty::HASH, &block)
        super(name, __entity_options__(options, block))
      end

      def attribute!(name, options = ::Kind::Empty::HASH, &block)
        super(name, __entity_options__(options, block))
      end

      private

        def __entity_options__(options, block)
          return options if !block && !__entity_accept?(options)

          opts = options.dup

          opts[:accept] = Class.new(::Micro::Entity).tap { |klass| klass.class_eval(&block) } if block

          entity_class = opts[:accept]

          if entity_class.is_a?(Class) && entity_class <= ::Micro::Entity && !opts.key?(:default)
            opts[:default] = ->(value) { value.is_a?(::Hash) ? entity_class.new(value) : value }
          end

          opts
        end

        def __entity_accept?(options)
          return false unless options.is_a?(::Hash)

          accept = options[:accept]

          accept.is_a?(::Class) && accept <= ::Micro::Entity
        end
    end

    class Strict < Entity
      include ::Micro::Attributes::Features::Accept::Strict
      include ::Micro::Attributes::Features::Initialize::Strict
    end
  end
end
