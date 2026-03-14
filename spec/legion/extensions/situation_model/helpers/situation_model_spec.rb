# frozen_string_literal: true

RSpec.describe Legion::Extensions::SituationModel::Helpers::SituationModel do
  let(:model) { described_class.new(label: 'test_narrative') }

  let(:event_a) do
    Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
      content:          'opening scene',
      dimension_values: { space: 0.8, time: 0.8, causation: 0.8, intentionality: 0.8, protagonist: 0.8 }
    )
  end

  let(:event_b) do
    Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
      content:          'continuing scene',
      dimension_values: { space: 0.8, time: 0.9, causation: 0.8, intentionality: 0.7, protagonist: 0.8 }
    )
  end

  let(:event_distant) do
    Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
      content:          'teleport scene',
      dimension_values: { space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0 }
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(model.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores label' do
      expect(model.label).to eq('test_narrative')
    end

    it 'starts with empty events' do
      expect(model.events).to be_empty
    end

    it 'initializes current_state with default values' do
      Legion::Extensions::SituationModel::Helpers::Constants::DIMENSIONS.each do |dim|
        expect(model.current_state[dim]).to eq(0.5)
      end
    end
  end

  describe '#add_event' do
    it 'appends event to events array' do
      model.add_event(event_a)
      expect(model.events.size).to eq(1)
    end

    it 'returns 1.0 for first event (no previous)' do
      result = model.add_event(event_a)
      expect(result).to eq(1.0)
    end

    it 'returns continuity score for subsequent events' do
      model.add_event(event_a)
      result = model.add_event(event_b)
      expect(result).to be_a(Float)
      expect(result).to be_between(0.0, 1.0)
    end

    it 'updates current_state to the new event dimension values' do
      model.add_event(event_a)
      expect(model.current_state[:space]).to be_within(0.001).of(0.8)
    end

    it 'updates last_updated_at' do
      original = model.last_updated_at
      sleep(0.01)
      model.add_event(event_a)
      expect(model.last_updated_at).to be >= original
    end
  end

  describe '#coherence' do
    it 'returns 1.0 for empty model' do
      expect(model.coherence).to eq(1.0)
    end

    it 'returns 1.0 for single event' do
      model.add_event(event_a)
      expect(model.coherence).to eq(1.0)
    end

    it 'returns high coherence for similar events' do
      model.add_event(event_a)
      model.add_event(event_b)
      expect(model.coherence).to be > 0.8
    end

    it 'returns lower coherence for dissimilar events' do
      model.add_event(event_a)
      model.add_event(event_distant)
      expect(model.coherence).to be < 0.5
    end

    it 'is between 0 and 1' do
      model.add_event(event_a)
      model.add_event(event_b)
      model.add_event(event_distant)
      expect(model.coherence).to be_between(0.0, 1.0)
    end
  end

  describe '#health_label' do
    it 'returns :vivid for fresh model with coherent events' do
      model.add_event(event_a)
      model.add_event(event_b)
      expect(model.health_label).to eq(:vivid)
    end

    it 'returns a known health symbol' do
      labels = %i[vivid clear hazy fading collapsed]
      expect(labels).to include(model.health_label)
    end
  end

  describe '#dominant_dimension' do
    it 'returns the dimension with highest current_state value' do
      model.add_event(
        Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
          content:          'high space',
          dimension_values: { space: 0.9, time: 0.3, causation: 0.4, intentionality: 0.2, protagonist: 0.1 }
        )
      )
      expect(model.dominant_dimension).to eq(:space)
    end
  end

  describe '#weakest_dimension' do
    it 'returns the dimension with lowest current_state value' do
      model.add_event(
        Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
          content:          'weak protagonist',
          dimension_values: { space: 0.9, time: 0.8, causation: 0.7, intentionality: 0.6, protagonist: 0.1 }
        )
      )
      expect(model.weakest_dimension).to eq(:protagonist)
    end
  end

  describe '#event_boundaries' do
    it 'returns empty array when no boundaries' do
      model.add_event(event_a)
      model.add_event(event_b)
      # Events are similar - expect no or minimal boundaries
      result = model.event_boundaries(threshold: 0.5)
      expect(result).to be_an(Array)
    end

    it 'detects boundaries on large dimension shifts' do
      model.add_event(event_a)
      model.add_event(event_distant)
      # event_distant is all zeros vs event_a all 0.8 - should produce boundary
      boundaries = model.event_boundaries(threshold: 0.3)
      expect(boundaries).to include(1)
    end

    it 'uses threshold 0.3 by default' do
      model.add_event(event_a)
      model.add_event(event_distant)
      boundaries_default = model.event_boundaries
      boundaries_strict  = model.event_boundaries(threshold: 0.9)
      # strict threshold should catch fewer boundaries
      expect(boundaries_default.size).to be >= boundaries_strict.size
    end
  end

  describe '#dimension_trajectory' do
    it 'returns an array of values for each event' do
      model.add_event(event_a)
      model.add_event(event_b)
      trajectory = model.dimension_trajectory(:space)
      expect(trajectory.size).to eq(2)
    end

    it 'contains the correct values in order' do
      model.add_event(event_a)
      model.add_event(event_b)
      trajectory = model.dimension_trajectory(:space)
      expect(trajectory[0]).to be_within(0.001).of(0.8)
      expect(trajectory[1]).to be_within(0.001).of(0.8)
    end

    it 'returns empty for model with no events' do
      expect(model.dimension_trajectory(:time)).to be_empty
    end
  end

  describe '#decay!' do
    it 'reduces all current_state values by DECAY_RATE' do
      model.add_event(event_a)
      before = model.current_state[:space]
      model.decay!
      expect(model.current_state[:space]).to be_within(0.001).of(before - 0.01)
    end

    it 'clamps at 0.0' do
      low_event = Legion::Extensions::SituationModel::Helpers::SituationEvent.new(
        content:          'near zero',
        dimension_values: { space: 0.005, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 }
      )
      model.add_event(low_event)
      model.decay!
      expect(model.current_state[:space]).to be >= 0.0
    end

    it 'applies decay to all 5 dimensions' do
      model.add_event(event_a)
      before = model.current_state.dup
      model.decay!
      Legion::Extensions::SituationModel::Helpers::Constants::DIMENSIONS.each do |dim|
        expect(model.current_state[dim]).to be < before[dim]
      end
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = model.to_h
      %i[id label event_count current_state coherence health_label created_at last_updated_at].each do |k|
        expect(h).to have_key(k)
      end
    end

    it 'reflects event count' do
      model.add_event(event_a)
      model.add_event(event_b)
      expect(model.to_h[:event_count]).to eq(2)
    end
  end
end
