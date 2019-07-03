# frozen_string_literal: true

require "micro/attributes/version"
require "micro/attributes/macros"

module Micro
  module Attributes
    def self.included(base)
      base.extend Macros

      base.class_eval do
        private_class_method :__attribute
        private_class_method :__attributes
        private_class_method :__attributes_defaults
      end

      def base.inherited(subclass)
        self.attributes_data({}) do |data|
          values = data.each_with_object(a: [], h: {}) do |(k, v), m|
            v.nil? ? m[:a] << k : m[:h][k] = v
          end

          subclass.attributes(values[:a])
          subclass.attributes(values[:h])
        end
      end
    end

    def self.to_initialize
      @to_initialize ||= Module.new do
        def self.included(base)
          base.send(:include, Micro::Attributes)

          base.class_eval(<<-RUBY)
            def initialize(params); self.attributes = params; end
            def with_attribute(key, val); self.class.new(attributes.merge(key => val)); end
            def with_attributes(params); self.class.new(attributes.merge(params)); end
          RUBY
        end
      end
    end

    def attribute?(name)
      self.class.attribute?(name)
    end

    def attributes=(params)
      self.class.attributes_data(params) do |data|
        data.each do |name, value|
          instance_variable_set("@#{name}", data[name]) if attribute?(name)
        end
      end
    end

    def attributes
      state =
        self.class.attributes.each_with_object({}) do |name, memo|
          iv_name = "@#{name}"
          is_defined = instance_variable_defined?(iv_name)
          memo[name] = instance_variable_get(iv_name) if is_defined
        end

      self.class.attributes_data(state) { |data| data }
    end

    protected :attributes=
  end
end
