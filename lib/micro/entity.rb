# frozen_string_literal: true

require 'micro/attributes'

module Micro
  class Entity
    include ::Micro::Attributes.with(:initialize, :accept, :diff)

    class << self
      # Mix an extra feature module into this entity subclass. Sugar for
      # `include ::Micro::Attributes.with(*names)` — accepts every form
      # the lower-level `with` does:
      #
      #   with :keys_as_symbol
      #   with :keys_as_symbol, :activemodel_validations
      #   with initialize: :strict
      #   with :keys_as_symbol, initialize: :strict, accept: :strict
      #
      # `:initialize`, `:accept`, and `:diff` are already bundled into
      # `Micro::Entity`, so re-including them is a no-op.
      def with(*names)
        include ::Micro::Attributes.with(*names)
      end

      def attribute(name, options = ::Kind::Empty::HASH, &block)
        super(name, __entity_options__(name, options, block))
      end

      def attribute!(name, options = ::Kind::Empty::HASH, &block)
        super(name, __entity_options__(name, options, block))
      end

      private

        def __entity_options__(name, options, block)
          return options unless block

          options = options.dup
          options[:accept] = __build_inline_entity__(name, block)
          options
        end

        # Build the anonymous nested entity AND give it a stable `to_s` /
        # `inspect`. Without this, `Accept`'s `Validate::KindOf.accept_failed`
        # interpolates the class with `#{exp}`, which on an anonymous class
        # renders `#<Class:0x000000012345>` — leaking the object id into
        # user-facing error messages. Naming it via singleton methods keeps
        # rejection messages deterministic and readable.
        def __build_inline_entity__(name, block)
          klass = Class.new(__entity_block_parent__)
          klass.class_eval(&block)

          outer_label = self.name || self.to_s
          inline_label = "#{outer_label}(#{name})"

          klass.define_singleton_method(:to_s)    { inline_label }
          klass.define_singleton_method(:inspect) { inline_label }

          klass
        end

        # Pick the parent class for an inline (block-form) nested entity.
        # We use one of the gem-provided "feature bases" (`Micro::Entity`
        # or `Micro::Entity::Strict`) so the inline class is isolated from
        # `self`'s ancestry:
        #
        # - No leak from parent / grandparent user attributes (via the
        #   `inherited` hook copying `__attributes_data__`).
        # - No leak from sibling attributes added to `self` AFTER the
        #   block runs (Ruby's dynamic dispatch would otherwise expose
        #   them via inherited `attr_reader`s).
        #
        # The tradeoff: features the user mixed in on intermediate
        # classes (e.g. `include Micro::Attributes.with(:keys_as_symbol)`)
        # don't propagate to inline children — define the nested entity
        # explicitly and pass it via `accept:` for those cases.
        def __entity_block_parent__
          self <= ::Micro::Entity::Strict ? ::Micro::Entity::Strict : ::Micro::Entity
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
