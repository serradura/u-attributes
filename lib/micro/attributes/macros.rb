# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      def __attributes
        @__attributes ||= Set.new
      end

      def __attribute_reader(name)
        __attributes.add(name)
        attr_reader(name)
      end

      def __attributes_data
        @__attributes_data ||= {}
      end

      def __attribute_set(key, value, allow_overwriting)
        name = key.to_s
        has_attribute = attribute?(name)
        __attribute_reader(name) unless has_attribute
        __attributes_data[name] = value if allow_overwriting || !has_attribute
      end

      def __attributes_set(args, allow_overwriting)
        args.flatten.each do |arg|
          if arg.is_a?(::Hash)
            arg.each { |key, val| __attribute_set(key, val, allow_overwriting) }
          else
            __attribute_set(arg, nil, allow_overwriting)
          end
        end
      end

      def attribute?(name)
        __attributes.member?(name.to_s)
      end

      def attribute(name, value=nil)
        __attribute_set(name, value, false)
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?
        __attributes_set(args, allow_overwriting: false)
      end

      def attributes_data(arg)
        __attributes_data.merge(AttributesUtils.stringify_hash_keys!(arg))
      end

      module ForSubclasses
        def attribute!(name, value=nil)
          __attribute_set(name, value, true)
        end

        def attributes!(*args)
          return __attributes_set(args, allow_overwriting: true) unless args.empty?
          raise ArgumentError, 'wrong number of arguments (given 0, expected 1 or more)'
        end
      end
      private_constant :ForSubclasses
    end
    private_constant :Macros
  end
end
