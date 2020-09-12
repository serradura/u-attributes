# frozen_string_literal: true

require 'micro/attributes/with'

module Micro
  module Attributes
    module Features
      extend self

      module Name
        ALL = [
          DIFF = 'diff'.freeze,
          INITIALIZE = 'initialize'.freeze,
          KEYS_AS_SYMBOL = 'keys_as_symbol'.freeze,
          ACTIVEMODEL_VALIDATIONS = 'activemodel_validations'.freeze
        ].sort.freeze
      end

      module Options
        KEYS = [
          DIFF = 'Diff'.freeze,
          INIT = 'Init'.freeze,
          INIT_STRICT = 'InitStrict'.freeze,
          KEYS_AS_SYMBOL = 'KeysAsSymbol'.freeze,
          AM_VALIDATIONS = 'AMValidations'.freeze
        ].sort.freeze

        NAMES_TO_KEYS = {
          Name::DIFF => DIFF,
          Name::INITIALIZE => INIT,
          Name::KEYS_AS_SYMBOL => KEYS_AS_SYMBOL,
          Name::ACTIVEMODEL_VALIDATIONS => AM_VALIDATIONS
        }.freeze

        KEYS_TO_MODULES = {
          DIFF => With::Diff,
          INIT => With::Initialize,
          INIT_STRICT => With::StrictInitialize,
          KEYS_AS_SYMBOL => With::KeysAsSymbol,
          AM_VALIDATIONS => With::ActiveModelValidations
        }.freeze

        def self.fetch_key(arg)
          if arg.is_a?(Hash)
            INIT_STRICT if arg[:initialize] == :strict
          else
            name = String(arg)

            return name if KEYS_TO_MODULES.key?(name)

            NAMES_TO_KEYS[name]
          end
        end

        INVALID_NAME = [
          'Invalid feature name! Available options: ',
          Name::ALL.map { |feature_name| ":#{feature_name}" }.join(', ')
        ].join

        def self.fetch_keys(args)
          keys = Array(args).dup.map { |name| fetch_key(name) }

          raise ArgumentError, INVALID_NAME if keys.empty? || !(keys - KEYS).empty?

          yield(keys)
        end

        def self.remove_init_keys(keys, if_has_init_in:)
          keys.delete_if { |key| key == INIT || key == INIT_STRICT } if if_has_init_in.include?(INIT)
        end

        def self.without_keys(keys_to_exclude)
          (KEYS - keys_to_exclude).tap do |keys|
            remove_init_keys(keys, if_has_init_in: keys_to_exclude)
          end
        end

        def self.fetch_module_by_keys(keys)
          keys.delete_if { |key| key == INIT } if keys.include?(INIT_STRICT)

          option = keys.sort.join('_')

          KEYS_TO_MODULES.fetch(option) { With.const_get(option, false) }
        end
      end

      def all
        @all ||= self.with(Options::KEYS)
      end

      def with(names)
        Options.fetch_keys(names) do |keys|
          Options.fetch_module_by_keys(keys)
        end
      end

      def without(names)
        Options.fetch_keys(names) do |keys|
          keys = Options.without_keys(keys)

          keys.empty? ? ::Micro::Attributes : Options.fetch_module_by_keys(keys)
        end
      end
    end
  end
end
