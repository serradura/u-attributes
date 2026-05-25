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
        # Read every declared attribute via its ivar (public + private +
        # protected) instead of going through `#attributes`, which only
        # exposes public ones. This restores the 3.0.x round-trip
        # behavior: `with_attribute(:foo, val)` preserves private/
        # protected values on the new instance even though they no
        # longer appear in the public `#attributes` hash.
        self.class.new(__all_attributes.merge(arg))
      end

      def with_attribute(key, val)
        with_attributes(key => val)
      end
    end
  end
end
