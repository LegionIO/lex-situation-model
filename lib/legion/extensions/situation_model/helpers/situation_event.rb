# frozen_string_literal: true

module Legion
  module Extensions
    module SituationModel
      module Helpers
        class SituationEvent
          include Constants

          attr_reader :content, :dimension_values, :created_at

          def initialize(content:, dimension_values: {})
            @content          = content
            @dimension_values = build_dimension_values(dimension_values)
            @created_at       = Time.now.utc
          end

          def continuity_with(other_event)
            total_diff = DIMENSIONS.sum do |dim|
              (dimension_values[dim] - other_event.dimension_values[dim]).abs
            end
            avg_diff = total_diff / DIMENSIONS.size.to_f
            1.0 - avg_diff
          end

          def discontinuous_dimensions(other_event, threshold: 0.3)
            DIMENSIONS.select do |dim|
              (dimension_values[dim] - other_event.dimension_values[dim]).abs > threshold
            end
          end

          def to_h
            {
              content:          content,
              dimension_values: dimension_values,
              created_at:       created_at.iso8601
            }
          end

          private

          def build_dimension_values(values)
            DIMENSIONS.to_h do |dim|
              raw = values.fetch(dim, DEFAULT_DIMENSION_VALUE)
              [dim, raw.clamp(0.0, 1.0)]
            end
          end
        end
      end
    end
  end
end
