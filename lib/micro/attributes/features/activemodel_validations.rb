# frozen_string_literal: true

module Micro::Attributes
  module Features
    module ActiveModelValidations
      def self.included(base)
        begin
          require 'active_model'

          base.send(:include, ::ActiveModel::Validations)
        rescue LoadError
        end
      end

      private

        def __call_after_micro_attribute
          run_validations! if respond_to?(:run_validations!, true)
        end
    end
  end
end
