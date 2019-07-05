# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      def __attributes
        @__attributes ||= Set.new
      end

      def attribute?(name)
        __attributes.member?(name.to_s)
      end

      def __attribute(name)
        return false if attribute?(name)

        __attributes.add(name)
        attr_reader(name)

        return true
      end

      def __attributes_data
        @__attributes_data ||= {}
      end

      def __attribute_data(name, value, allow_to_override)
        __attributes_data[name] = value if allow_to_override || __attribute(name)
      end

      def __attribute_data!(arg, allow_to_override:)
        return __attribute_data(arg.to_s, nil, allow_to_override) unless arg.is_a?(Hash)

        arg.each { |key, value| __attribute_data(key.to_s, value, allow_to_override) }
      end

      def attribute(arg)
        __attribute_data!(arg, allow_to_override: false)
      end

      def attribute!(arg)
        __attribute_data!(arg, allow_to_override: true)
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?

        args.flatten.each { |arg| attribute(arg) }
      end

      def attributes!(*args)
        args.flatten.each { |arg| attribute!(arg) }
      end

      def attributes_data(arg)
        __attributes_data.merge(
          Utils.hash_argument!(arg)
               .each_with_object({}) { |(key, val), memo| memo[key.to_s] = val }
        )
      end
    end
  end
end
