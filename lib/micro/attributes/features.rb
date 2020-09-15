# frozen_string_literal: true

module Micro
  module Attributes
    module With
    end

    module Features
      require 'micro/attributes/features/diff'
      require 'micro/attributes/features/accept'
      require 'micro/attributes/features/initialize'
      require 'micro/attributes/features/initialize/strict'
      require 'micro/attributes/features/keys_as_symbol'
      require 'micro/attributes/features/activemodel_validations'

      extend self

      module Name
        ALL = [
          DIFF = 'diff'.freeze,
          ACCEPT = 'accept'.freeze,
          INITIALIZE = 'initialize'.freeze,
          KEYS_AS_SYMBOL = 'keys_as_symbol'.freeze,
          ACTIVEMODEL_VALIDATIONS = 'activemodel_validations'.freeze
        ].sort.freeze
      end

      module Options
        KEYS = [
          DIFF = 'Diff'.freeze,
          INIT = 'Initialize'.freeze,
          ACCEPT = 'Accept'.freeze,
          INIT_STRICT = 'InitializeStrict'.freeze,
          KEYS_AS_SYMBOL = 'KeysAsSymbol'.freeze,
          AM_VALIDATIONS = 'ActiveModelValidations'.freeze
        ].sort.freeze

        KEYS_TO_FEATURES = {
          DIFF => Features::Diff,
          INIT => Features::Initialize,
          ACCEPT => Features::Accept,
          INIT_STRICT => Features::Initialize::Strict,
          KEYS_AS_SYMBOL => Features::KeysAsSymbol,
          AM_VALIDATIONS => Features::ActiveModelValidations
        }.freeze

        NAMES_TO_KEYS = {
          Name::DIFF => DIFF,
          Name::ACCEPT => ACCEPT,
          Name::INITIALIZE => INIT,
          Name::KEYS_AS_SYMBOL => KEYS_AS_SYMBOL,
          Name::ACTIVEMODEL_VALIDATIONS => AM_VALIDATIONS
        }.freeze

        BuildKey = -> combination do
          key = combination.sort.join('_')
          key.sub("#{INIT}_#{INIT_STRICT}", INIT_STRICT)
        end

        KEYS_TO_MODULES = begin
          combinations = (1..KEYS.size).map { |n| KEYS.combination(n).to_a }.flatten(1).sort_by { |i| "#{i.size}#{i.join}" }
          combinations.delete_if { |combination| combination.include?(INIT_STRICT) && !combination.include?(INIT) }
          combinations.each_with_object({}) do |combination, features|
            included = [
              'def self.included(base)',
              '  base.send(:include, ::Micro::Attributes)',
              combination.map { |key| "  base.send(:include, ::#{KEYS_TO_FEATURES[key].name})" },
              'end'
            ].flatten.join("\n")

            key = BuildKey.call(combination)

            With.const_set(key, Module.new.tap { |mod| mod.instance_eval(included) })

            features[key] = With.const_get(key, false)
          end.freeze
        end

        def self.fetch_key(arg)
          if arg.is_a?(Hash)
            INIT_STRICT if arg[:initialize] == :strict
          else
            name = String(arg)

            KEYS_TO_MODULES.key?(name) ? name : NAMES_TO_KEYS[name]
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

        def self.remove_init_key_if_has_init_strict(keys)
          keys.delete_if { |key| key == INIT } if keys.include?(INIT_STRICT)
        end

        def self.remove_init_keys(keys, if_has_init_in:)
          keys.delete_if { |key| key == INIT || key == INIT_STRICT } if if_has_init_in.include?(INIT)
        end

        def self.without_keys(keys_to_exclude)
          (KEYS - keys_to_exclude).tap do |keys|
            remove_init_keys(keys, if_has_init_in: keys_to_exclude)
          end
        end

        def self.fetch_module_by_keys(combination)
          key = BuildKey.call(combination)

          KEYS_TO_MODULES.fetch(key)
        end
      end

      def all
        @all ||= self.with(Options::KEYS)
      end

      def with(names)
        Options.fetch_keys(names) do |keys|
          Options.remove_init_key_if_has_init_strict(keys)

          Options.fetch_module_by_keys(keys)
        end
      end

      def without(names)
        Options.fetch_keys(names) do |keys|
          keys_to_fetch = Options.without_keys(keys)

          return ::Micro::Attributes if keys_to_fetch.empty?

          Options.fetch_module_by_keys(keys_to_fetch)
        end
      end
    end
  end
end
