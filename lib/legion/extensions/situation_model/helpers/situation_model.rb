# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SituationModel
      module Helpers
        class SituationModel
          include Constants

          attr_reader :id, :label, :events, :current_state, :created_at, :last_updated_at

          def initialize(label:)
            @id             = SecureRandom.uuid
            @label          = label
            @events         = []
            @current_state  = DIMENSIONS.to_h { |dim| [dim, DEFAULT_DIMENSION_VALUE] }
            @created_at     = Time.now.utc
            @last_updated_at = Time.now.utc
          end

          def add_event(event)
            previous = events.last
            events << event
            @current_state   = event.dimension_values.dup
            @last_updated_at = Time.now.utc
            previous ? event.continuity_with(previous) : 1.0
          end

          def coherence
            return 1.0 if events.size <= 1

            pairs = events.each_cons(2).to_a
            total = pairs.sum { |a, b| b.continuity_with(a) }
            (total / pairs.size.to_f).clamp(COHERENCE_FLOOR, COHERENCE_CEILING)
          end

          def health_label
            c = coherence
            MODEL_HEALTH_LABELS.find { |range, _| range.cover?(c) }&.last || :collapsed
          end

          def dominant_dimension
            current_state.max_by { |_, v| v }&.first
          end

          def weakest_dimension
            current_state.min_by { |_, v| v }&.first
          end

          def event_boundaries(threshold: 0.3)
            indices = []
            events.each_cons(2).with_index do |(a, b), idx|
              indices << (idx + 1) unless b.discontinuous_dimensions(a, threshold: threshold).empty?
            end
            indices
          end

          def dimension_trajectory(dimension)
            events.map { |e| e.dimension_values[dimension] }
          end

          def decay!
            DIMENSIONS.each do |dim|
              current_state[dim] = (current_state[dim] - DECAY_RATE).clamp(COHERENCE_FLOOR, COHERENCE_CEILING)
            end
          end

          def to_h
            {
              id:              id,
              label:           label,
              event_count:     events.size,
              current_state:   current_state,
              coherence:       coherence,
              health_label:    health_label,
              created_at:      created_at.iso8601,
              last_updated_at: last_updated_at.iso8601
            }
          end
        end
      end
    end
  end
end
