# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Initialize
      def self.included(base)
        base.class_eval(<<-RUBY)
          def initialize(arg)
            self.attributes = arg
          end
        RUBY
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
