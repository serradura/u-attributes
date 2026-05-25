# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      module Options
        PERMITTED = [
          :default, :required, :freeze, :protected, :private, # for all
          :validate, :validates,                              # for ext: activemodel_validations
          :accept, :reject, :allow_nil, :rejection_message    # for ext: accept
        ].freeze

        INVALID_MESSAGE = [
          "Found one or more invalid options: %{invalid_options}\n\nThe valid ones are: ",
          PERMITTED.map { |key| ":#{key}" }.join(', ')
        ].join.freeze

        def self.check(opt)
          invalid_keys = opt.keys - PERMITTED

          return if invalid_keys.empty?

          invalid_options = { invalid_options: invalid_keys.inspect.tr('[', '').tr(']', '') }

          raise ArgumentError, (INVALID_MESSAGE % invalid_options)
        end

        def self.for_accept(opt)
          allow_nil = opt[:allow_nil]
          rejection_message = opt[:rejection_message]

          return [:accept, opt[:accept], allow_nil, rejection_message] if opt.key?(:accept)
          return [:reject, opt[:reject], allow_nil, rejection_message] if opt.key?(:reject)

          Kind::Empty::ARRAY
        end

        ALL = 0
        PUBLIC = 1
        PRIVATE = 2
        PROTECTED = 3
        REQUIRED = 4

        def self.visibility_index(opt)
          return PRIVATE if opt[:private]
          return PROTECTED if opt[:protected]
          PUBLIC
        end

        VISIBILITY_NAMES = { PUBLIC => :public, PRIVATE => :private, PROTECTED => :protected }.freeze

        def self.visibility_name_from_index(visibility_index)
          VISIBILITY_NAMES[visibility_index]
        end

        def self.private?(visibility); visibility == PRIVATE; end
        def self.protected?(visibility); visibility == PROTECTED; end
      end

      def attributes_are_all_required?
        false
      end

      def attributes_access
        :indifferent
      end

      def __attributes_groups
        @__attributes_groups ||= [
          Set.new, # all
          Set.new, # public
          [],      # private
          [],      # protected
          Set.new, # required
        ]
      end

      def __attributes; __attributes_groups[Options::ALL]; end

      def __attributes_public; __attributes_groups[Options::PUBLIC]; end

      def __attributes_required__; __attributes_groups[Options::REQUIRED]; end

      def __attribute_key_check__(value)
        value
      end

      def __attribute_key_transform__(value)
        value.to_s
      end

      def __attributes_keys_transform__(hash)
        Utils::Hashes.stringify_keys(hash)
      end

      # NOTE: can't be renamed! It is used by u-case v4.
      def __attributes_data__
        @__attributes_data__ ||= {}
      end

      def __attribute_reader(name, visibility_index)
        attr_reader(name)

        __attributes.add(name)
        __attributes_groups[visibility_index] << name

        private(name) if Options.private?(visibility_index)
        protected(name) if Options.protected?(visibility_index)
      end

      # Re-apply visibility for an already-defined attribute. Used by
      # `attribute!` so a subclass can promote a private/protected
      # parent attribute back to public (or change visibility in either
      # direction). Without this, `__attributes_data__` would say one
      # thing while the actual reader's Ruby visibility said another.
      #
      # Note — `attribute!` is authoritative here: if the user defined a
      # custom reader method (`def name; ...; end`) between the parent's
      # `attribute` and the child's `attribute!`, this call will adjust
      # that custom method's Ruby visibility too. That matches the
      # documented "redefine these attributes" contract of `attribute!`.
      def __attribute_reapply_visibility(name, visibility_index)
        [Options::PUBLIC, Options::PRIVATE, Options::PROTECTED].each do |idx|
          __attributes_groups[idx].delete(name)
        end
        __attributes_groups[visibility_index] << name

        if Options.private?(visibility_index)
          private(name)
        elsif Options.protected?(visibility_index)
          protected(name)
        else
          public(name)
        end
      end

      # Sync the required set with the new options. Name kept for backwards
      # compat with downstream gems (u-case v4) that may introspect it —
      # the method is now add-or-remove rather than add-only so that
      # `attribute!` on a child can relax a parent's required attribute
      # by giving it a default (or vice-versa).
      def __attributes_required_add(name, opt, hasnt_default)
        if opt[:required] || (attributes_are_all_required? && hasnt_default)
          __attributes_required__.add(name)
        else
          __attributes_required__.delete(name)
        end

        nil
      end

      def __attributes_data_to_assign(name, opt, visibility_index)
        hasnt_default = !opt.key?(:default)

        __attributes_required_add(name, opt, hasnt_default)

        [
          hasnt_default ? nil : opt[:default],
          Options.for_accept(opt),
          opt[:freeze],
          Options.visibility_name_from_index(visibility_index)
        ]
      end

      def __call_after_attribute_assign__(attr_name, options); end

      def __attribute_assign(key, can_overwrite, opt)
        name = __attribute_key_check__(__attribute_key_transform__(key))

        Options.check(opt)

        has_attribute = attribute?(name, true)

        visibility_index = Options.visibility_index(opt)

        __attribute_reader(name, visibility_index) unless has_attribute

        if can_overwrite || !has_attribute
          __attributes_data__[name] = __attributes_data_to_assign(name, opt, visibility_index)
          __attribute_reapply_visibility(name, visibility_index) if has_attribute
        end

        __call_after_attribute_assign__(name, opt)
      end

      # NOTE: can't be renamed! It is used by u-case v4.
      def __attributes_set_after_inherit__(arg)
        arg.each do |key, val|
          opt = {}

          default = val[0]
          accept_key, accept_val = val[1]
          freeze, visibility = val[2], val[3]

          opt[:default] = default if default
          opt[accept_key] = accept_val if accept_key
          opt[:freeze] = freeze if freeze
          opt[visibility] = true if visibility != :public

          __attribute_assign(key, true, opt || Kind::Empty::HASH)
        end
      end

      def attribute?(name, include_all = false)
        key = __attribute_key_transform__(name)

        return __attributes.member?(key) if include_all

        __attributes_public.member?(key)
      end

      def attribute(name, options = Kind::Empty::HASH, &block)
        options = __micro_attributes_block_options__(name, options, block) if block
        __attribute_assign(name, false, options)
      end

      # Mix more `Micro::Attributes` features into this class. Sugar for
      # `include Micro::Attributes.with(*names)` — accepts the same forms,
      # including the hash-style API (e.g. `with initialize: :strict`).
      #
      #   with :keys_as_symbol
      #   with :keys_as_symbol, :activemodel_validations
      #   with initialize: :strict, accept: :strict
      def with(*names)
        send(:include, ::Micro::Attributes.with(*names))
      end

      private

        def __micro_attributes_block_options__(name, options, block)
          options = options.dup
          options[:accept] = __micro_attributes_build_inline_class__(name, block)
          options
        end

        # Build an anonymous nested class for `attribute :foo do ... end`.
        #
        # The inline class is wired with `Micro::Attributes.with(...)` so it
        # always has a hash-keyword constructor and accept-validation
        # machinery (the bare minimum for block-form to be useful). On top
        # of that default, every `Features::*` module already in the host's
        # ancestors is replayed — so a `KeysAsSymbol` / `ActiveModelValidations`
        # / `Strict` host yields an inline child with the same mix.
        #
        # This handles three host patterns:
        # - `include Micro::Attributes.with(...)` — features come from With::*
        #   in ancestors, replayed below.
        # - bare `include Micro::Attributes` — defaults to init+accept.
        # - direct `include Micro::Attributes::Features::*` (the `u-case`
        #   pattern) — same detection path picks them up.
        def __micro_attributes_build_inline_class__(name, block)
          klass = Class.new
          klass.send(:include, ::Micro::Attributes.with(*__micro_attributes_inline_features__))

          klass.class_eval(&block)

          # Lazy outer label — capture the host class OBJECT (not its
          # `.name` string) so naming resolves AFTER any later constant
          # assignment (matters for `Micro::Attributes.new { ... }`,
          # where the constant is assigned only after the factory returns).
          outer = self
          label_proc = -> { "#{outer.name || outer.inspect}(#{name})" }

          klass.define_singleton_method(:to_s,    &label_proc)
          klass.define_singleton_method(:inspect, &label_proc)

          # Stop instances from leaking the anonymous class's heap address
          # via the default `Object#inspect`. The new inspect:
          # - uses `self.class.to_s` (stable via the singleton above)
          # - surfaces ONLY public attribute values — consults
          #   `attributes_by_visibility[:public]` so private/protected
          #   values aren't leaked
          # - which also hides framework ivars like ActiveModel's
          #   `@errors`, `@validation_context`, etc., since they aren't
          #   declared attributes
          klass.send(:define_method, :inspect) do
            public_attrs = self.class.attributes_by_visibility[:public]
            present = public_attrs.select { |n| instance_variable_defined?("@#{n}") }

            if present.empty?
              "#<#{self.class}>"
            else
              body = present.map { |n| "@#{n}=#{instance_variable_get("@#{n}").inspect}" }.join(', ')
              "#<#{self.class} #{body}>"
            end
          end

          # ActiveModel-aware naming — but ONLY when the inline class
          # actually has AM mixed in. AM's error renderer reaches for
          # `klass.model_name`, which on an anonymous class defaults to
          # `ActiveModel::Name.new(klass)` and raises "Class name cannot
          # be blank". The singleton override provides the explicit name.
          #
          # We DO NOT define the override on non-AM inline classes,
          # because that would flip `respond_to?(:model_name)` from
          # false → true on AM-less hosts and break any duck-typing
          # feature-detection (`if klass.respond_to?(:model_name); ...`).
          if defined?(::ActiveModel::Validations) && klass.include?(::ActiveModel::Validations)
            klass.define_singleton_method(:model_name) do
              ::ActiveModel::Name.new(self, nil, label_proc.call)
            end
          end

          klass
        end

        # Detect every Micro::Attributes feature module already in the host's
        # ancestors and map it back to the args `Micro::Attributes.with` accepts.
        # Always includes `:initialize` and `:accept` defaults so block-form
        # attributes can be hash-constructed and type-checked.
        FEATURE_NAME_TO_ARG = {
          'Micro::Attributes::Features::Initialize'              => :initialize,
          'Micro::Attributes::Features::Accept'                  => :accept,
          'Micro::Attributes::Features::Diff'                    => :diff,
          'Micro::Attributes::Features::KeysAsSymbol'            => :keys_as_symbol,
          'Micro::Attributes::Features::ActiveModelValidations'  => :activemodel_validations
        }.freeze

        STRICT_NAME_TO_VARIANT = {
          'Micro::Attributes::Features::Initialize::Strict' => :initialize,
          'Micro::Attributes::Features::Accept::Strict'     => :accept
        }.freeze

        def __micro_attributes_inline_features__
          features = [:initialize, :accept]
          strict   = {}

          ancestors.each do |mod|
            next unless mod.is_a?(::Module) && mod.name

            if (arg = FEATURE_NAME_TO_ARG[mod.name])
              features << arg
            elsif (key = STRICT_NAME_TO_VARIANT[mod.name])
              strict[key] = :strict
            end
          end

          features.uniq!
          features << strict unless strict.empty?
          features
        end

      public

      RaiseKindError = ->(expected, given) do
        if (util = Kind.const_get(:KIND, false)) && util.respond_to?(:error!)
          util.error!(expected, given)
        else
          raise Kind::Error.new(expected, given, label: nil)
        end
      end

      private_constant :RaiseKindError

      def attributes(*args)
        return __attributes.to_a if args.empty?

        args.flatten!

        options =
          args.size > 1 && args.last.is_a?(::Hash) ? args.pop : Kind::Empty::HASH

        args.each do |arg|
          if arg.is_a?(String) || arg.is_a?(Symbol)
            __attribute_assign(arg, false, options)
          else
            RaiseKindError.call('String/Symbol'.freeze, arg)
          end
        end
      end

      def attributes_by_visibility
        {
          public: __attributes_groups[Options::PUBLIC].to_a,
          private: __attributes_groups[Options::PRIVATE].dup,
          protected: __attributes_groups[Options::PROTECTED].dup
        }
      end

      # NOTE: can't be renamed! It is used by u-case v4.
      module ForSubclasses
        WRONG_NUMBER_OF_ARGS = 'wrong number of arguments (given 0, expected 1 or more)'.freeze

        def attribute!(name, options = Kind::Empty::HASH, &block)
          options = __micro_attributes_block_options__(name, options, block) if block
          __attribute_assign(name, true, options)
        end

        private_constant :WRONG_NUMBER_OF_ARGS
      end

      private_constant :Options, :ForSubclasses
    end

    private_constant :Macros
  end
end
