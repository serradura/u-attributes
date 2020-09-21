# frozen_string_literal: true

module Micro::Attributes
  module Features
    module ActiveModelValidations
      module Standard
        private def __call_after_attributes_assign
          run_validations!
        end
      end

      module CheckActivemodelValidationErrors
        private def __check_activemodel_validation_errors
          return if errors.blank?

          errors_hash = errors.to_hash

          defined_attributes.each do |key|
            value = Utils::Hashes.assoc(errors_hash, key)

            @__attributes_errors[key] = value.join(', ') if value.present?
          end
        end
      end

      module WithAccept
        include CheckActivemodelValidationErrors

        private def __call_after_attributes_assign
          run_validations! unless attributes_errors?

          __check_activemodel_validation_errors
        end
      end

      module WithAcceptStrict
        include CheckActivemodelValidationErrors

        private def __call_after_attributes_assign
          __raise_error_if_found_attributes_errors if attributes_errors?

          run_validations!

          __check_activemodel_validation_errors
        end
      end

      module ClassMethods
        def __call_after_attribute_assign__(attr_name, options)
          validate, validates = options.values_at(:validate, :validates)

          self.validate(validate) if validate
          self.validates(attr_name, validates.dup) if validates
        end
      end

      def self.included(base)
        begin
          require 'active_model'

          base.send(:include, ::ActiveModel::Validations)
          base.extend(ClassMethods)

          case
          when base <= Features::Accept::Strict then base.send(:include, WithAcceptStrict)
          when base <= Features::Accept then base.send(:include, WithAccept)
          else base.send(:include, Standard)
          end
        rescue LoadError
        end
      end

      private_constant :Standard, :CheckActivemodelValidationErrors, :WithAccept, :WithAcceptStrict
    end
  end
end
