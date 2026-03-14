# frozen_string_literal: true

module Legion
  module Extensions
    module SituationModel
      module Helpers
        class Client
          include Legion::Extensions::SituationModel::Runners::SituationModel

          private

          def engine
            @engine ||= SituationEngine.new
          end
        end
      end
    end
  end
end
