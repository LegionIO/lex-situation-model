# frozen_string_literal: true

RSpec.describe Legion::Extensions::SituationModel::Helpers::SituationEvent do
  let(:default_dims) { { space: 0.5, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 } }
  let(:event_a)      { described_class.new(content: 'hero walks into room', dimension_values: default_dims) }
  let(:event_b)      { described_class.new(content: 'hero walks forward', dimension_values: default_dims) }

  describe '#initialize' do
    it 'stores content' do
      expect(event_a.content).to eq('hero walks into room')
    end

    it 'stores all 5 dimension values' do
      expect(event_a.dimension_values.keys).to contain_exactly(*Legion::Extensions::SituationModel::Helpers::Constants::DIMENSIONS)
    end

    it 'defaults missing dimensions to 0.5' do
      event = described_class.new(content: 'test')
      expect(event.dimension_values[:space]).to eq(0.5)
    end

    it 'clamps dimension values to [0, 1]' do
      event = described_class.new(content: 'test', dimension_values: { space: 1.5, time: -0.3 })
      expect(event.dimension_values[:space]).to eq(1.0)
      expect(event.dimension_values[:time]).to eq(0.0)
    end

    it 'records created_at timestamp' do
      expect(event_a.created_at).to be_a(Time)
    end
  end

  describe '#continuity_with' do
    it 'returns 1.0 for identical events' do
      expect(event_a.continuity_with(event_b)).to be_within(0.001).of(1.0)
    end

    it 'returns 0.0 when all dimensions are maximally different' do
      e1 = described_class.new(content: 'a', dimension_values: { space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0 })
      e2 = described_class.new(content: 'b', dimension_values: { space: 1.0, time: 1.0, causation: 1.0, intentionality: 1.0, protagonist: 1.0 })
      expect(e1.continuity_with(e2)).to be_within(0.001).of(0.0)
    end

    it 'returns intermediate value for partial differences' do
      e1 = described_class.new(content: 'a', dimension_values: { space: 0.0, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      e2 = described_class.new(content: 'b', dimension_values: { space: 1.0, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      # Only space differs by 1.0, avg diff = 1.0/5 = 0.2, continuity = 0.8
      expect(e1.continuity_with(e2)).to be_within(0.001).of(0.8)
    end

    it 'is symmetric' do
      e1 = described_class.new(content: 'x', dimension_values: { space: 0.2, time: 0.8, causation: 0.5, intentionality: 0.3, protagonist: 0.7 })
      e2 = described_class.new(content: 'y', dimension_values: { space: 0.6, time: 0.4, causation: 0.9, intentionality: 0.1, protagonist: 0.5 })
      expect(e1.continuity_with(e2)).to be_within(0.001).of(e2.continuity_with(e1))
    end
  end

  describe '#discontinuous_dimensions' do
    it 'returns empty for identical events' do
      expect(event_a.discontinuous_dimensions(event_b)).to be_empty
    end

    it 'returns dimensions that exceed threshold' do
      e1 = described_class.new(content: 'a', dimension_values: { space: 0.0, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      e2 = described_class.new(content: 'b', dimension_values: { space: 0.8, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      result = e1.discontinuous_dimensions(e2, threshold: 0.3)
      expect(result).to include(:space)
      expect(result).not_to include(:time, :causation, :intentionality, :protagonist)
    end

    it 'uses threshold 0.3 by default' do
      e1 = described_class.new(content: 'a', dimension_values: { space: 0.0, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      e2 = described_class.new(content: 'b', dimension_values: { space: 0.5, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      # space differs by 0.5 > 0.3
      expect(e1.discontinuous_dimensions(e2)).to include(:space)
    end

    it 'respects custom threshold' do
      e1 = described_class.new(content: 'a', dimension_values: { space: 0.0, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      e2 = described_class.new(content: 'b', dimension_values: { space: 0.4, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 })
      # space diff = 0.4, with threshold 0.5 should NOT be discontinuous
      expect(e1.discontinuous_dimensions(e2, threshold: 0.5)).not_to include(:space)
    end
  end

  describe '#to_h' do
    it 'includes content, dimension_values, and created_at' do
      h = event_a.to_h
      expect(h[:content]).to eq('hero walks into room')
      expect(h[:dimension_values]).to be_a(Hash)
      expect(h[:created_at]).to be_a(String)
    end
  end
end
