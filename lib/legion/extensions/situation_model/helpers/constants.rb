# frozen_string_literal: true

module Legion
  module Extensions
    module SituationModel
      module Helpers
        module Constants
          DIMENSIONS = %i[space time causation intentionality protagonist].freeze

          CONTINUITY_LABELS = {
            (0.8..)     => :continuous,
            (0.5...0.8) => :shift,
            (0.2...0.5) => :break,
            (..0.2)     => :rupture
          }.freeze

          MODEL_HEALTH_LABELS = {
            (0.8..)     => :vivid,
            (0.6...0.8) => :clear,
            (0.4...0.6) => :hazy,
            (0.2...0.4) => :fading,
            (..0.2)     => :collapsed
          }.freeze

          MAX_MODELS            = 100
          MAX_EVENTS_PER_MODEL  = 200
          MAX_HISTORY           = 500
          DEFAULT_DIMENSION_VALUE = 0.5
          DECAY_RATE            = 0.01
          COHERENCE_FLOOR       = 0.0
          COHERENCE_CEILING     = 1.0
        end
      end
    end
  end
end
