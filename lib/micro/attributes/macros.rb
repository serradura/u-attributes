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

      def __attributes_def(arg, can_overwrite)
        return __attribute_set(arg, nil, can_overwrite) unless arg.is_a?(::Hash)
        arg.each { |key, val| __attribute_set(key, val, can_overwrite) }
      end

      def __attributes_set(args, can_overwrite)
        args.flatten.each { |arg| __attributes_def(arg, can_overwrite) }
      end

      def attribute?(name)
        __attributes.member?(name.to_s)
      end

      def attribute(name, value=nil)
        __attribute_set(name, value, false)
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?
        __attributes_set(args, can_overwrite: false)
      end

      def attributes_data(arg)
        __attributes_data.merge(AttributesUtils.stringify_hash_keys!(arg))
      end

      module ForSubclasses
        WRONG_NUMBER_OF_ARGS = 'wrong number of arguments (given 0, expected 1 or more)'.freeze

        def attribute!(name, value=nil)
          __attribute_set(name, value, true)
        end

        def attributes!(*args)
          return __attributes_set(args, can_overwrite: true) unless args.empty?
          raise ArgumentError, WRONG_NUMBER_OF_ARGS
        end

        private_constant :WRONG_NUMBER_OF_ARGS
      end
      private_constant :ForSubclasses
    end
    private_constant :Macros
  end
end
