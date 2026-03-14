# frozen_string_literal: true

module Legion
  module Extensions
    module SituationModel
      module Helpers
        class SituationEngine
          include Constants

          def initialize
            @models = {}
          end

          def create_model(label:)
            model = SituationModel.new(label: label)
            @models[model.id] = model
            model
          end

          def add_event_to_model(model_id:, content:, dimension_values: {})
            model = @models[model_id]
            return nil unless model

            event = SituationEvent.new(content: content, dimension_values: dimension_values)
            model.add_event(event)
            event
          end

          def model_coherence(model_id:)
            @models[model_id]&.coherence
          end

          def find_boundaries(model_id:, threshold: 0.3)
            @models[model_id]&.event_boundaries(threshold: threshold)
          end

          def dimension_trajectory(model_id:, dimension:)
            @models[model_id]&.dimension_trajectory(dimension)
          end

          def most_coherent(limit: 5)
            @models.values
                   .sort_by { |m| -m.coherence }
                   .first(limit)
          end

          def models_by_label(label:)
            @models.values.select { |m| m.label == label }
          end

          def decay_all
            @models.each_value(&:decay!)
          end

          def prune_collapsed
            @models.delete_if { |_, m| m.coherence <= 0.1 }
          end

          def to_h
            {
              model_count: @models.size,
              models:      @models.values.map(&:to_h)
            }
          end
        end
      end
    end
  end
end
