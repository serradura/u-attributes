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
          return options unless block

          options = options.dup
          options[:accept] = Class.new(__entity_block_parent__).tap { |klass| klass.class_eval(&block) }
          options
        end

        # Inline (block-form) nested entities inherit from the immediate
        # superclass when it's a Micro::Entity descendant — so a Strict
        # parent yields a Strict inline child. Falls back to the plain
        # `Micro::Entity` base otherwise.
        def __entity_block_parent__
          parent = superclass
          parent <= ::Micro::Entity ? parent : ::Micro::Entity
        end
    end

    # Coerce nested hashes into entity instances at attribute-assign time
    # (before `accept:` checks run). Entity instances pass through untouched.
    #
    # Implemented as a `prepend` so the coercion sits in front of the
    # `Accept` feature's `__attribute_assign` — `super` then routes the
    # already-coerced value through the normal accept/freeze/visibility path.
    # Compared to using a `default:` proc, this preserves the user's options
    # untouched so strict-mode "all attributes required" still works.
    module Coercion
      private

        def __attribute_assign(key, init_hash, attribute_data)
          accept = attribute_data[1]

          if accept[0] == :accept && (klass = accept[1]).is_a?(::Class) && klass <= ::Micro::Entity
            value = init_hash[key]

            if value.is_a?(::Hash)
              init_hash = init_hash.dup
              init_hash[key] = klass.new(value)
            end
          end

          super(key, init_hash, attribute_data)
        end
    end

    prepend Coercion

    class Strict < Entity
      include ::Micro::Attributes.with(initialize: :strict, accept: :strict)
    end
  end
end
