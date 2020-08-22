# frozen_string_literal: true

module Micro::Attributes
  module Features
    module ActiveModelValidations
      def self.included(base)
        begin
          require 'active_model'

          base.send(:include, ::ActiveModel::Validations)
          base.extend(ClassMethods)
        rescue LoadError
        end
      end

      module ClassMethods
        def __call_after_attribute_assign__(attr_name, options)
          validate, validates = options.values_at(:validate, :validates)

          self.validate(validate) if validate
          self.validates(attr_name, validates) if validates
        end
      end

      private

        def __call_after_micro_attribute
          run_validations! if respond_to?(:run_validations!, true)
        end
    end
  end
end
