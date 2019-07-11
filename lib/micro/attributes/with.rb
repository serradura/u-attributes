# frozen_string_literal: true

require 'micro/attributes/features/diff'
require 'micro/attributes/features/initialize'
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

      module ActiveModelValidations
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      #
      # Combinations
      #
      module DiffAndInitialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module ActiveModelValidationsAndDiff
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module ActiveModelValidationsAndInitialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      module ActiveModelValidationsAndDiffAndInitialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end
    end
  end
end
