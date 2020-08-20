# frozen_string_literal: true

require 'micro/attributes/with'

module Micro
  module Attributes
    module Features
      extend self

      STRICT_INITIALIZE = 'strict_initialize'.freeze

      ALL_VISIBLE = [
        DIFF = 'diff'.freeze,
        INITIALIZE = 'initialize'.freeze,
        ACTIVEMODEL_VALIDATIONS = 'activemodel_validations'.freeze
      ].sort.freeze

      ALL = (ALL_VISIBLE + [STRICT_INITIALIZE]).sort.freeze

      INVALID_NAME = [
        'Invalid feature name! Available options: ',
        ALL_VISIBLE.map { |feature_name| ":#{feature_name}" }.join(', ')
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
        'activemodel_validations:diff:strict_initialize' => With::ActiveModelValidationsAndDiffAndStrictInitialize
      }.freeze

      private_constant :OPTIONS, :INVALID_NAME

      def all
        @all ||= self.with(ALL)
      end

      def with(args)
        valid_names!(args) do |names|
          delete_initialize_if_has_strict_initialize(names)

          OPTIONS.fetch(names.sort.join(':'))
        end
      end

      def without(args)
        valid_names!(args) do |names_to_exclude|
          names = except_options(names_to_exclude)
          names.empty? ? ::Micro::Attributes : self.with(names)
        end
      end

      private

        def fetch_feature_name(name)
          return name unless name.is_a?(Hash)

          STRICT_INITIALIZE if name[:initialize] == :strict
        end

        def normalize_names(args)
          names = Array(args).dup

          last_feature = fetch_feature_name(names.pop)

          features = names.empty? ? [last_feature] : names + [last_feature]
          features.map! { |name| name.to_s.downcase }
          features.uniq
        end

        def valid_names?(names)
          names.all? { |name| ALL.include?(name) }
        end

        def valid_names!(args)
          names = normalize_names(args)

          raise ArgumentError, INVALID_NAME if names.empty? || !valid_names?(names)

          yield(names)
        end

        def an_initialize?(name)
          name == INITIALIZE || name == STRICT_INITIALIZE
        end

        def delete_initialize_if_has_strict_initialize(names)
          return unless names.include?(STRICT_INITIALIZE)

          names.delete_if { |name| name == INITIALIZE }
        end

        def except_options(names_to_exclude)
          (ALL - names_to_exclude).tap do |names|
            names.delete_if { |name| an_initialize?(name) } if names_to_exclude.include?(INITIALIZE)

            delete_initialize_if_has_strict_initialize(names)
          end
        end
    end
  end
end
