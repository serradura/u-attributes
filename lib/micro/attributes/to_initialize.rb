# frozen_string_literal: true

module Micro
  module Attributes
    module ToInitialize
      def self.included(base)
        base.send(:include, ::Micro::Attributes)
      end

      def initialize(arg)
        self.attributes = arg
      end

      def with_attribute(key, val)
        self.class.new(attributes.merge(key => val))
      end

      def with_attributes(arg)
        self.class.new(attributes.merge(arg))
      end
    end
  end
end
