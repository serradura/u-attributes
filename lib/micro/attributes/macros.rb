# frozen_string_literal: true

module Micro
  module Attributes
    module Macros
      def __attributes_defaults
        @__attributes_defaults ||= {}
      end

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

      def attribute(arg)
        return __attribute(arg.to_s) unless arg.is_a?(Hash)

        arg.each do |key, value|
          name = key.to_s
          __attributes_defaults[name] = value if __attribute(name)
        end
      end

      def attributes(*args)
        return __attributes.to_a if args.empty?

        args.flatten.each { |arg| attribute(arg) }
      end

      def attributes_data(arg)
        normalized_params = arg.keys.each_with_object({}) do |key, memo|
          memo[key.to_s] = arg[key]
        end

        undefineds = (self.attributes - normalized_params.keys)
        nil_params =
          undefineds.each_with_object({}) { |name, memo| memo[name] = nil }

        yield(
          normalized_params.merge!(nil_params).merge!(__attributes_defaults)
        )
      end
    end
  end
end
