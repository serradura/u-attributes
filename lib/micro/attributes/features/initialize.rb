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

      def with_attributes(arg)
        self.class.new(attributes.merge(arg))
      end

      def with_attribute(key, val)
        with_attributes(key => val)
      end
    end
  end
end
