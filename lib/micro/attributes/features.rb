# frozen_string_literal: true

require "micro/attributes/features/diff"
require "micro/attributes/features/initialize"

module Micro
  module Attributes
    module Features
      module InitializeAndDiff
        def self.included(base)
          base.send(:include, ::Micro::Attributes::Features::Initialize)
          base.send(:include, ::Micro::Attributes::Features::Diff)
        end
      end

      OPTIONS = {
        'diff' => Diff,
        'initialize' => Initialize,
        'diff:initialize' => InitializeAndDiff
      }.freeze

      private_constant :OPTIONS

      def self.fetch(names)
        option = OPTIONS[names.map { |name| name.to_s.downcase }.sort.join(':')]
        return option if option
        raise ArgumentError, 'Invalid feature name! Available options: diff, initialize'
      end
    end
  end
end
