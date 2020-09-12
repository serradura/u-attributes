# frozen_string_literal: true

require 'micro/attributes/features/diff'
require 'micro/attributes/features/initialize'
require 'micro/attributes/features/initialize/strict'
require 'micro/attributes/features/keys_as_symbol'
require 'micro/attributes/features/activemodel_validations'


module Micro
  module Attributes
    module With
      #
      # Features
      #
      module Diff
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module Initialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
        end
      end

      module StrictInitialize
        def self.included(base)
          base.send(:include, Initialize)
          base.send(:include, ::Micro::Attributes::Features::Initialize::Strict)
        end
      end

      module KeysAsSymbol
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module ActiveModelValidations
        def self.included(base)
          base.send(:include, Initialize)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      #
      # Combinations
      #
      module AMValidations_Diff
        def self.included(base)
          base.send(:include, ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module AMValidations_Diff_Init
        def self.included(base)
          base.send(:include, ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module AMValidations_Diff_Init_KeysAsSymbol
        def self.included(base)
          base.send(:include, ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Diff)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module AMValidations_Diff_InitStrict
        def self.included(base)
          base.send(:include, AMValidations_Diff_Init)
          base.send(:include, ::Micro::Attributes::Features::Initialize::Strict)
        end
      end

      module AMValidations_Diff_InitStrict_KeysAsSymbol
        def self.included(base)
          base.send(:include, AMValidations_Diff_Init)
          base.send(:include, ::Micro::Attributes::Features::Initialize::Strict)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module AMValidations_Diff_KeysAsSymbol
        def self.included(base)
          base.send(:include, AMValidations_Diff)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module AMValidations_Init
        def self.included(base)
          base.send(:include, ActiveModelValidations)
        end
      end

      module AMValidations_Init_KeysAsSymbol
        def self.included(base)
          base.send(:include, AMValidations_Init)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module AMValidations_InitStrict
        def self.included(base)
          base.send(:include, ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Initialize::Strict)
        end
      end

      module AMValidations_InitStrict_KeysAsSymbol
        def self.included(base)
          base.send(:include, AMValidations_InitStrict)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module AMValidations_KeysAsSymbol
        def self.included(base)
          base.send(:include, ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module Diff_Init
        def self.included(base)
          base.send(:include, Initialize)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module Diff_Init_KeysAsSymbol
        def self.included(base)
          base.send(:include, Diff_Init)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module Diff_InitStrict
        def self.included(base)
          base.send(:include, Diff_Init)
          base.send(:include, ::Micro::Attributes::Features::Initialize::Strict)
        end
      end

      module Diff_InitStrict_KeysAsSymbol
        def self.included(base)
          base.send(:include, Diff_InitStrict)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module Diff_KeysAsSymbol
        def self.included(base)
          base.send(:include, Diff)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module Init_KeysAsSymbol
        def self.included(base)
          base.send(:include, Initialize)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end

      module InitStrict_KeysAsSymbol
        def self.included(base)
          base.send(:include, StrictInitialize)
          base.send(:include, ::Micro::Attributes::Features::KeysAsSymbol)
        end
      end
    end
  end
end
