# frozen_string_literal: true

module Micro::Attributes
  module Features
    module ActiveModelValidations
      @@__active_model_load_error = false
      @@__active_model_required = false

      def self.included(base)
        if !@@__active_model_load_error && !@@__active_model_required
          begin
            require 'active_model'
          rescue LoadError => e
            @@__active_model_load_error = true
          end
          @@__active_model_required = true
        end

        unless @@__active_model_load_error
          base.send(:include, ::ActiveModel::Validations)

          if ::ActiveModel::VERSION::STRING >= '3.2'
            base.class_eval(<<-RUBY)
              def initialize(arg)
                self.attributes=arg
                run_validations!
              end
            RUBY
          end
        end
      end
    end
  end
end
