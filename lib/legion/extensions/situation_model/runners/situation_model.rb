# frozen_string_literal: true

module Legion
  module Extensions
    module SituationModel
      module Runners
        module SituationModel
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_situation_model(label:, **)
            model = engine.create_model(label: label)
            Legion::Logging.debug "[situation_model] create_model: id=#{model.id} label=#{label}"
            { success: true, model: model.to_h }
          end

          def add_situation_event(model_id:, content:, **opts)
            dim_values = {
              space:          opts.fetch(:space, 0.5),
              time:           opts.fetch(:time, 0.5),
              causation:      opts.fetch(:causation, 0.5),
              intentionality: opts.fetch(:intentionality, 0.5),
              protagonist:    opts.fetch(:protagonist, 0.5)
            }
            event = engine.add_event_to_model(model_id: model_id, content: content, dimension_values: dim_values)
            unless event
              Legion::Logging.debug "[situation_model] add_event: model_id=#{model_id} not found"
              return { success: false, error: 'model not found' }
            end

            coherence = engine.model_coherence(model_id: model_id)
            Legion::Logging.debug "[situation_model] add_event: model_id=#{model_id} coherence=#{coherence.round(3)}"
            { success: true, event: event.to_h, coherence: coherence }
          end

          def situation_model_coherence(model_id:, **)
            coherence = engine.model_coherence(model_id: model_id)
            Legion::Logging.debug "[situation_model] coherence: model_id=#{model_id} value=#{coherence}"
            return { success: false, error: 'model not found' } if coherence.nil?

            { success: true, model_id: model_id, coherence: coherence }
          end

          def find_situation_boundaries(model_id:, threshold: 0.3, **)
            boundaries = engine.find_boundaries(model_id: model_id, threshold: threshold)
            Legion::Logging.debug "[situation_model] boundaries: model_id=#{model_id} count=#{boundaries&.size}"
            return { success: false, error: 'model not found' } if boundaries.nil?

            { success: true, model_id: model_id, boundaries: boundaries, threshold: threshold }
          end

          def situation_dimension_trajectory(model_id:, dimension:, **)
            dim = dimension.to_sym
            trajectory = engine.dimension_trajectory(model_id: model_id, dimension: dim)
            Legion::Logging.debug "[situation_model] trajectory: model_id=#{model_id} dimension=#{dim} points=#{trajectory&.size}"
            return { success: false, error: 'model not found' } if trajectory.nil?

            { success: true, model_id: model_id, dimension: dim, trajectory: trajectory }
          end

          def most_coherent_situations(limit: 5, **)
            models = engine.most_coherent(limit: limit)
            Legion::Logging.debug "[situation_model] most_coherent: limit=#{limit} found=#{models.size}"
            { success: true, models: models.map(&:to_h), count: models.size }
          end

          def situations_by_label(label:, **)
            models = engine.models_by_label(label: label)
            Legion::Logging.debug "[situation_model] by_label: label=#{label} found=#{models.size}"
            { success: true, label: label, models: models.map(&:to_h), count: models.size }
          end

          def update_situation_models(**)
            engine.decay_all
            pruned = engine.prune_collapsed
            Legion::Logging.debug "[situation_model] update: decay_all pruned=#{pruned.size}"
            { success: true, pruned_count: pruned.size }
          end

          def situation_model_stats(**)
            stats = engine.to_h
            Legion::Logging.debug "[situation_model] stats: model_count=#{stats[:model_count]}"
            { success: true, **stats }
          end

          private

          def engine
            @engine ||= Helpers::SituationEngine.new
          end
        end
      end
    end
  end
end
