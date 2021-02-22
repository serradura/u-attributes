# frozen_string_literal: true

module Micro::Attributes
  module Features
    module KeysAsSymbol

      module ClassMethods
        def attributes_access
          :symbol
        end

        def __attribute_key_check__(value)
          Kind::Symbol[value]
        end

        def __attribute_key_transform__(value)
          value
        end

        def __attributes_keys_transform__(hash)
          Kind::Hash[hash]
        end
      end

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

    end
  end
end
