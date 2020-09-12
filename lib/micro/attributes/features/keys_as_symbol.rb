# frozen_string_literal: true

module Micro::Attributes
  module Features
    module KeysAsSymbol

      module ClassMethods
        def attributes_access
          :symbol
        end

        def __attribute_access__(value)
          Kind::Of.(::Symbol, value)
        end

        def __attribute_key__(value)
          value
        end

        def __attributes_keys__(hash)
          Utils::Hashes.kind(hash)
        end
      end

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

    end
  end
end
