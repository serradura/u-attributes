# frozen_string_literal: true

require "micro/attributes/with"

module Micro
  module Attributes
    module Features
      INVALID_FEATURES = 'Invalid feature name! Available options: :initialize, :strict_initialize, :diff, :activemodel_validations'.freeze

      OPTIONS = {
        # Features
        'diff' => With::Diff,
        'initialize' => With::Initialize,
        'strict_initialize' => With::StrictInitialize,
        'activemodel_validations' => With::ActiveModelValidations,
        # Combinations
        'diff:initialize' => With::DiffAndInitialize,
        'diff:strict_initialize' => With::DiffAndStrictInitialize,
        'activemodel_validations:diff' => With::ActiveModelValidationsAndDiff,
        'activemodel_validations:initialize' => With::ActiveModelValidationsAndInitialize,
        'activemodel_validations:strict_initialize' => With::ActiveModelValidationsAndStrictInitialize,
        'activemodel_validations:diff:initialize' => With::ActiveModelValidationsAndDiffAndInitialize,
        'activemodel_validations:diff:strict_initialize' => With::ActiveModelValidationsAndDiffAndStrictInitialize
      }.freeze

      private_constant :OPTIONS

      def self.all
        With::ActiveModelValidationsAndDiffAndInitialize
      end

      def self.with(names)
        option = OPTIONS[names.map { |name| name.to_s.downcase }.sort.join(':')]
        return option if option
        raise ArgumentError, INVALID_FEATURES
      end

      def self.options(init, diff, activemodel_validations)
        [init].tap do |options|
          options << :diff if diff
          options << :activemodel_validations if activemodel_validations
        end
      end
    end
  end
end
