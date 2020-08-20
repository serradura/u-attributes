# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Diff
      def diff_attributes(to)
        return Micro::Attributes::Diff::Changes.new(from: self, to: to) if to.is_a?(::Micro::Attributes)

        raise ArgumentError, "#{to.inspect} must implement Micro::Attributes"
      end
    end
  end
end
