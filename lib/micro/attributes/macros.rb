# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      def attributes_are_all_required?
        false
      end

      # NOTE: can't be renamed! It is used by u-case v4.
      def __attributes_data__
        @__attributes_data__ ||= {}
      end

      def __attributes_required__
        @__attributes_required__ ||= Set.new
      end

      def __attributes_required_add(name, is_required, hasnt_default)
        if is_required || (attributes_are_all_required? && hasnt_default)
          __attributes_required__.add(name)
        end

        nil
      end

      def __attributes_data_to_assign(name, options)
        hasnt_default = !options.key?(:default)

        hasnt_default ? __attributes_required_add(name, options[:required], hasnt_default) : options[:default]
      end

      def __attributes
        @__attributes ||= Set.new
      end

      def __attribute_reader(name)
        __attributes.add(name)

        attr_reader(name)
      end

      def __attribute_assign(key, can_overwrite, options)
        name = key.to_s
        has_attribute = attribute?(name)

        __attribute_reader(name) unless has_attribute

        __attributes_data__[name] = __attributes_data_to_assign(name, options) if can_overwrite || !has_attribute

        __call_after_attribute_assign__(name, options)
      end

      def __call_after_attribute_assign__(attr_name, options); end

      # NOTE: can't be renamed! It is used by u-case v4.
      def __attributes_set_after_inherit__(arg)
        arg.each { |key, val| __attribute_assign(key, true, default: val) }
      end

      def attribute?(name)
        __attributes.member?(name.to_s)
      end

      def attribute(name, options = Kind::Empty::HASH)
        __attribute_assign(name, false, options)
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?

        args.flatten!
        args.each do |arg|
          if arg.is_a?(String) || arg.is_a?(Symbol)
            __attribute_assign(arg, false, Kind::Empty::HASH)
          else
            raise Kind::Error.new('String/Symbol'.freeze, arg)
          end
        end
      end

      # NOTE: can't be renamed! It is used by u-case v4.
      module ForSubclasses
        WRONG_NUMBER_OF_ARGS = 'wrong number of arguments (given 0, expected 1 or more)'.freeze

        def attribute!(name, options = Kind::Empty::HASH)
          __attribute_assign(name, true, options)
        end

        private_constant :WRONG_NUMBER_OF_ARGS
      end

      private_constant :ForSubclasses
    end

    private_constant :Macros
  end
end
