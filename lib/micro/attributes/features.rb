# frozen_string_literal: true

require "micro/attributes/features/diff"
require "micro/attributes/features/initialize"
require "micro/attributes/features/activemodel_validations"

module Micro
  module Attributes
    module Features
      module InitializeAndDiff
        def self.included(base)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      module ActiveModelValidationsAndDiff
        def self.included(base)
          base.send(:include, ::Micro::Attributes::Features::Diff)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      module ActiveModelValidationsAndInitialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      module ActiveModelValidationsAndDiffAndInitialize
        def self.included(base)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::Diff)
          base.send(:include, ::Micro::Attributes::Features::ActiveModelValidations)
        end
      end

      OPTIONS = {
        # Features
        'diff' => Diff,
        'initialize' => Initialize,
        'activemodel_validations' => ActiveModelValidations,
        # Combinations
        'diff:initialize' => InitializeAndDiff,
        'activemodel_validations:diff' => ActiveModelValidationsAndDiff,
        'activemodel_validations:initialize' => ActiveModelValidationsAndInitialize,
        'activemodel_validations:diff:initialize' => ActiveModelValidationsAndDiffAndInitialize
      }.freeze

      private_constant :OPTIONS

      def self.all
        ActiveModelValidationsAndDiffAndInitialize
      end

      def self.fetch(names)
        option = OPTIONS[names.map { |name| name.to_s.downcase }.sort.join(':')]
        return option if option
        raise ArgumentError, 'Invalid feature name! Available options: diff, initialize, activemodel_validations'
      end
    end
  end
end
