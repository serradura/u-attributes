# frozen_string_literal: true

module Micro
  module Attributes
    # Composition behavior baked into every `Micro::Attributes` includer.
    #
    # - `Coercion` (prepended): hashes assigned to an attribute whose
    #   `accept:` is another `Micro::Attributes` class are auto-built
    #   into instances of that class. Errors on the constructed child
    #   bubble up as `'is invalid'` markers in the parent's
    #   `attributes_errors` (when `Accept` is active).
    # - `Instance#__validate_nested_entities__` (included): walks nested
    #   `Micro::Attributes` children and surfaces their invalidity into
    #   ActiveModel `errors`. Auto-registered by
    #   `Features::ActiveModelValidations.included`.
    module Composition
      module Coercion
        private

          def __attribute_assign(key, init_hash, attribute_data)
            accept = attribute_data[1]

            # Only coerce when the target class has the `:initialize` feature
            # — without it there's no hash constructor and `klass.new(hash)`
            # would fall through to `Object#initialize` and raise ArgumentError.
            if accept[0] == :accept &&
               (klass = accept[1]).is_a?(::Class) &&
               klass.include?(::Micro::Attributes) &&
               klass.include?(::Micro::Attributes::Features::Initialize)
              value = init_hash[key]

              if value.is_a?(::Hash)
                init_hash = init_hash.dup
                init_hash[key] = klass.new(value)
              end
            end

            super(key, init_hash, attribute_data)

            # Bubble a marker for nested-entity errors — but only for PUBLIC
            # attributes. Mirror Accept's visibility gate so private/protected
            # attribute names don't leak through `attributes_errors`.
            child = instance_variable_get("@#{key}")
            if child.is_a?(::Object) &&
               child.class.include?(::Micro::Attributes) &&
               child.respond_to?(:attributes_errors?) && child.attributes_errors? &&
               @__attributes_errors && !@__attributes_errors.key?(key) &&
               attribute_data[3] == :public
              @__attributes_errors[key] = 'is invalid'
            end
          end
      end

      module Instance
        def __validate_nested_entities__
          return unless respond_to?(:errors)

          # Iterate only PUBLIC attributes so private/protected nested
          # entity names never leak through ActiveModel `errors` /
          # `full_messages`. Mirrors the bubble's visibility gate above.
          self.class.attributes_by_visibility[:public].each do |attr_name|
            child = instance_variable_get("@#{attr_name}")

            next unless child.is_a?(::Object) && child.class.include?(::Micro::Attributes)

            child_invalid =
              if child.respond_to?(:valid?)
                !child.valid?
              elsif child.respond_to?(:attributes_errors?)
                child.attributes_errors?
              else
                false
              end

            errors.add(attr_name.to_sym, 'is invalid') if child_invalid
          end
        end
      end
    end
  end
end
