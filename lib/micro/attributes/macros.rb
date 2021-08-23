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

      def __attributes_required_add(name, opt, hasnt_default)
        if opt[:required] || (attributes_are_all_required? && hasnt_default)
          __attributes_required__.add(name)
        end

        nil
      end

      def __attributes_data_to_assign(name, opt, visibility_index)
        hasnt_default = !opt.key?(:default)

        default = hasnt_default ? __attributes_required_add(name, opt, hasnt_default) : opt[:default]

        [
          default,
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

      def attribute(name, options = Kind::Empty::HASH)
        __attribute_assign(name, false, options)
      end

      RaiseKindError = ->(expected, given) do
        if Kind.const_get(:KIND, false)&.respond_to?(:error!)
          Kind::KIND.error!(expected, given)
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

        def attribute!(name, options = Kind::Empty::HASH)
          __attribute_assign(name, true, options)
        end

        private_constant :WRONG_NUMBER_OF_ARGS
      end

      private_constant :Options, :ForSubclasses
    end

    private_constant :Macros
  end
end
