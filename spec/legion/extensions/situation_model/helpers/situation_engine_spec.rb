# frozen_string_literal: true

RSpec.describe Legion::Extensions::SituationModel::Helpers::SituationEngine do
  let(:engine) { described_class.new }

  def add_coherent_events(model_id, count)
    count.times do |i|
      engine.add_event_to_model(
        model_id:         model_id,
        content:          "event #{i}",
        dimension_values: { space: 0.8, time: 0.8, causation: 0.8, intentionality: 0.8, protagonist: 0.8 }
      )
    end
  end

  describe '#create_model' do
    it 'returns a SituationModel' do
      model = engine.create_model(label: 'test')
      expect(model).to be_a(Legion::Extensions::SituationModel::Helpers::SituationModel)
    end

    it 'assigns the given label' do
      model = engine.create_model(label: 'narrative_x')
      expect(model.label).to eq('narrative_x')
    end

    it 'stores the model by id' do
      model = engine.create_model(label: 'stored')
      expect(engine.model_coherence(model_id: model.id)).not_to be_nil
    end
  end

  describe '#add_event_to_model' do
    it 'returns the created event' do
      model = engine.create_model(label: 'e')
      event = engine.add_event_to_model(model_id: model.id, content: 'hi')
      expect(event).to be_a(Legion::Extensions::SituationModel::Helpers::SituationEvent)
    end

    it 'returns nil for unknown model_id' do
      result = engine.add_event_to_model(model_id: 'nonexistent', content: 'x')
      expect(result).to be_nil
    end

    it 'grows the model event count' do
      model = engine.create_model(label: 'growing')
      engine.add_event_to_model(model_id: model.id, content: 'first')
      engine.add_event_to_model(model_id: model.id, content: 'second')
      expect(model.events.size).to eq(2)
    end

    it 'passes dimension values to the event' do
      model = engine.create_model(label: 'dims')
      engine.add_event_to_model(model_id: model.id, content: 'test',
                                dimension_values: { space: 0.9, time: 0.1, causation: 0.5,
                                                    intentionality: 0.5, protagonist: 0.5 })
      expect(model.events.last.dimension_values[:space]).to be_within(0.001).of(0.9)
    end
  end

  describe '#model_coherence' do
    it 'returns nil for unknown model' do
      expect(engine.model_coherence(model_id: 'bad')).to be_nil
    end

    it 'returns 1.0 for empty model' do
      model = engine.create_model(label: 'empty')
      expect(engine.model_coherence(model_id: model.id)).to eq(1.0)
    end

    it 'returns coherence value for model with events' do
      model = engine.create_model(label: 'coh')
      add_coherent_events(model.id, 3)
      expect(engine.model_coherence(model_id: model.id)).to be > 0.8
    end
  end

  describe '#find_boundaries' do
    it 'returns nil for unknown model' do
      expect(engine.find_boundaries(model_id: 'bad')).to be_nil
    end

    it 'returns empty array for highly coherent model' do
      model = engine.create_model(label: 'coherent')
      add_coherent_events(model.id, 3)
      expect(engine.find_boundaries(model_id: model.id, threshold: 0.5)).to be_empty
    end

    it 'detects discontinuities' do
      model = engine.create_model(label: 'jump')
      engine.add_event_to_model(model_id: model.id, content: 'high',
                                dimension_values: { space: 0.9, time: 0.9, causation: 0.9, intentionality: 0.9, protagonist: 0.9 })
      engine.add_event_to_model(model_id: model.id, content: 'low',
                                dimension_values: { space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0 })
      boundaries = engine.find_boundaries(model_id: model.id, threshold: 0.3)
      expect(boundaries).to include(1)
    end
  end

  describe '#dimension_trajectory' do
    it 'returns nil for unknown model' do
      expect(engine.dimension_trajectory(model_id: 'bad', dimension: :space)).to be_nil
    end

    it 'returns array of values for known dimension' do
      model = engine.create_model(label: 'traj')
      engine.add_event_to_model(model_id: model.id, content: 'a',
                                dimension_values: { space: 0.3, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      engine.add_event_to_model(model_id: model.id, content: 'b',
                                dimension_values: { space: 0.7, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      traj = engine.dimension_trajectory(model_id: model.id, dimension: :space)
      expect(traj).to eq([0.3, 0.7])
    end
  end

  describe '#most_coherent' do
    it 'returns models sorted by coherence desc' do
      m1 = engine.create_model(label: 'low')
      engine.add_event_to_model(model_id: m1.id, content: 'a',
                                dimension_values: { space: 0.9, time: 0.9, causation: 0.9, intentionality: 0.9, protagonist: 0.9 })
      engine.add_event_to_model(model_id: m1.id, content: 'b',
                                dimension_values: { space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0 })

      m2 = engine.create_model(label: 'high')
      add_coherent_events(m2.id, 3)

      results = engine.most_coherent(limit: 2)
      expect(results.first.id).to eq(m2.id)
    end

    it 'respects limit' do
      3.times { |i| engine.create_model(label: "m#{i}") }
      expect(engine.most_coherent(limit: 2).size).to eq(2)
    end
  end

  describe '#models_by_label' do
    it 'returns models matching label' do
      engine.create_model(label: 'alpha')
      engine.create_model(label: 'alpha')
      engine.create_model(label: 'beta')
      result = engine.models_by_label(label: 'alpha')
      expect(result.size).to eq(2)
      expect(result.all? { |m| m.label == 'alpha' }).to be(true)
    end

    it 'returns empty array for unknown label' do
      expect(engine.models_by_label(label: 'nope')).to be_empty
    end
  end

  describe '#decay_all' do
    it 'decays all models' do
      m1 = engine.create_model(label: 'a')
      m2 = engine.create_model(label: 'b')
      engine.add_event_to_model(model_id: m1.id, content: 'e1',
                                dimension_values: { space: 0.8, time: 0.8, causation: 0.8, intentionality: 0.8, protagonist: 0.8 })
      engine.add_event_to_model(model_id: m2.id, content: 'e2',
                                dimension_values: { space: 0.6, time: 0.6, causation: 0.6, intentionality: 0.6, protagonist: 0.6 })

      before_m1 = m1.current_state[:space]
      before_m2 = m2.current_state[:space]
      engine.decay_all
      expect(m1.current_state[:space]).to be < before_m1
      expect(m2.current_state[:space]).to be < before_m2
    end
  end

  describe '#prune_collapsed' do
    it 'removes models with coherence <= 0.1' do
      model = engine.create_model(label: 'collapse')
      # Add maximally discontinuous events repeatedly to drive coherence very low
      5.times do |i|
        engine.add_event_to_model(
          model_id:         model.id,
          content:          "e#{i}",
          dimension_values: if i.even?
                              { space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0 }
                            else
                              { space: 1.0, time: 1.0, causation: 1.0, intentionality: 1.0, protagonist: 1.0 }
                            end
        )
      end

      coherent_model = engine.create_model(label: 'coherent')
      add_coherent_events(coherent_model.id, 3)

      engine.prune_collapsed
      # coherent model should survive
      expect(engine.model_coherence(model_id: coherent_model.id)).not_to be_nil
    end
  end

  describe '#to_h' do
    it 'includes model_count and models' do
      engine.create_model(label: 'x')
      h = engine.to_h
      expect(h[:model_count]).to eq(1)
      expect(h[:models]).to be_an(Array)
      expect(h[:models].size).to eq(1)
    end
  end
end
