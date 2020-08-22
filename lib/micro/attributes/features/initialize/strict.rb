# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Initialize
      module Strict
        module ClassMethods
          def attributes_are_all_required?
            true
          end
        end

        def self.included(base)
          base.send(:extend, ClassMethods)
        end
      end
    end
  end
end
