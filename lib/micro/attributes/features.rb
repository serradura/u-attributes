# frozen_string_literal: true

require "micro/attributes/with"

module Micro
  module Attributes
    module Features
      ALL = [
        DIFF = 'diff'.freeze,
        INITIALIZE = 'initialize'.freeze,
        STRICT_INITIALIZE = 'strict_initialize'.freeze,
        ACTIVEMODEL_VALIDATIONS = 'activemodel_validations'.freeze
      ].sort.freeze

      INVALID_OPTION = [
        'Invalid feature name! Available options: ',
        ALL.map { |feature_name| ":#{feature_name}" }.join(', ')
      ].join

      OPTIONS = {
        # Features
        DIFF => With::Diff,
        INITIALIZE => With::Initialize,
        STRICT_INITIALIZE => With::StrictInitialize,
        ACTIVEMODEL_VALIDATIONS => With::ActiveModelValidations,
        # Combinations
        'diff:initialize' => With::DiffAndInitialize,
        'diff:strict_initialize' => With::DiffAndStrictInitialize,
        'activemodel_validations:diff' => With::ActiveModelValidationsAndDiff,
        'activemodel_validations:initialize' => With::ActiveModelValidationsAndInitialize,
        'activemodel_validations:strict_initialize' => With::ActiveModelValidationsAndStrictInitialize,
        'activemodel_validations:diff:initialize' => With::ActiveModelValidationsAndDiffAndInitialize,
        'activemodel_validations:diff:strict_initialize' => With::ActiveModelValidationsAndDiffAndStrictInitialize,
        ALL.join(':') => With::ActiveModelValidationsAndDiffAndStrictInitialize
      }.freeze

      private_constant :OPTIONS, :INVALID_OPTION

      def self.all
        @all ||= self.with(ALL)
      end

      def self.with(names)
        option = OPTIONS[names.map { |name| name.to_s.downcase }.uniq.sort.join(':')]
        return option if option
        raise ArgumentError, INVALID_OPTION
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
