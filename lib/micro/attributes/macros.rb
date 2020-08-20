# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      def __attributes_data
        @__attributes_data ||= {}
      end

      def __attributes
        @__attributes ||= Set.new
      end

      def __attribute_reader(name)
        __attributes.add(name)

        attr_reader(name)
      end

      def __attribute_set(key, value, can_overwrite)
        name = key.to_s
        has_attribute = attribute?(name)

        __attribute_reader(name) unless has_attribute
        __attributes_data[name] = value if can_overwrite || !has_attribute
      end

      def attribute?(name)
        __attributes.member?(name.to_s)
      end

      def attribute(name, default: nil)
        __attribute_set(name, default, false)
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?

        args.flatten.each do |arg|
          if arg.is_a?(String) || arg.is_a?(Symbol)
            __attribute_set(arg, nil, false)
          else
            raise Kind::Error.new('String/Symbol'.freeze, arg)
          end
        end
      end

      def __inherited_attributes_set__(arg)
        arg.each { |key, val| __attribute_set(key, val, true) }
      end

      def __attributes_data__(arg)
        __attributes_data.merge(Utils.stringify_hash_keys!(arg))
      end

      module ForSubclasses
        WRONG_NUMBER_OF_ARGS = 'wrong number of arguments (given 0, expected 1 or more)'.freeze

        def attribute!(name, default: nil)
          __attribute_set(name, default, true)
        end

        private_constant :WRONG_NUMBER_OF_ARGS
      end

      private_constant :ForSubclasses
    end

    private_constant :Macros
  end
end
