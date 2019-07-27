# frozen_string_literal: true

require "micro/attributes/with"

module Micro
  module Attributes
    module Features
      INVALID_FEATURES = 'Invalid feature name! Available options: :initialize, :diff, :activemodel_validations'.freeze

      OPTIONS = {
        # Features
        'diff' => With::Diff,
        'initialize' => With::Initialize,
        'activemodel_validations' => With::ActiveModelValidations,
        # Combinations
        'diff:initialize' => With::DiffAndInitialize,
        'activemodel_validations:diff' => With::ActiveModelValidationsAndDiff,
        'activemodel_validations:initialize' => With::ActiveModelValidationsAndInitialize,
        'activemodel_validations:diff:initialize' => With::ActiveModelValidationsAndDiffAndInitialize
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
    end
  end
end
