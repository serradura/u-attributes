# frozen_string_literal: true

require "micro/attributes/features/diff"
require "micro/attributes/features/initialize"

module Micro::Attributes
  module Features
    module InitializeAndDiff
      def self.included(base)
        base.send(:include, ::Micro::Attributes::Features::Initialize)
        base.send(:include, ::Micro::Attributes::Features::Diff)
      end
    end
  end
end
