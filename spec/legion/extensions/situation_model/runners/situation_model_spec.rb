# frozen_string_literal: true

require 'legion/extensions/situation_model/client'

RSpec.describe Legion::Extensions::SituationModel::Runners::SituationModel do
  let(:client) { Legion::Extensions::SituationModel::Client.new }

  def create_model(label: 'test')
    client.create_situation_model(label: label)
  end

  def add_event(model_id, content: 'test event', **dims)
    defaults = { space: 0.5, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5 }
    client.add_situation_event(model_id: model_id, content: content, **defaults.merge(dims))
  end

  describe '#create_situation_model' do
    it 'returns success: true' do
      result = create_model
      expect(result[:success]).to be(true)
    end

    it 'returns a model hash with id and label' do
      result = create_model(label: 'story')
      expect(result[:model][:label]).to eq('story')
      expect(result[:model][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#add_situation_event' do
    it 'returns success: true for known model' do
      model_id = create_model[:model][:id]
      result   = add_event(model_id)
      expect(result[:success]).to be(true)
    end

    it 'returns success: false for unknown model' do
      result = add_event('nonexistent')
      expect(result[:success]).to be(false)
      expect(result[:error]).to eq('model not found')
    end

    it 'returns coherence after adding event' do
      model_id = create_model[:model][:id]
      result   = add_event(model_id)
      expect(result[:coherence]).to be_a(Float)
    end

    it 'accepts custom dimension values' do
      model_id = create_model[:model][:id]
      result   = client.add_situation_event(model_id: model_id, content: 'scene',
                                            space: 0.9, time: 0.1,
                                            causation: 0.5, intentionality: 0.5, protagonist: 0.5)
      expect(result[:success]).to be(true)
      expect(result[:event][:dimension_values][:space]).to be_within(0.001).of(0.9)
    end
  end

  describe '#situation_model_coherence' do
    it 'returns success: true for known model' do
      model_id = create_model[:model][:id]
      result   = client.situation_model_coherence(model_id: model_id)
      expect(result[:success]).to be(true)
      expect(result[:coherence]).to be_a(Float)
    end

    it 'returns success: false for unknown model' do
      result = client.situation_model_coherence(model_id: 'bad')
      expect(result[:success]).to be(false)
    end
  end

  describe '#find_situation_boundaries' do
    it 'returns success: true for known model' do
      model_id = create_model[:model][:id]
      add_event(model_id)
      result = client.find_situation_boundaries(model_id: model_id)
      expect(result[:success]).to be(true)
      expect(result[:boundaries]).to be_an(Array)
    end

    it 'returns success: false for unknown model' do
      result = client.find_situation_boundaries(model_id: 'bad')
      expect(result[:success]).to be(false)
    end

    it 'uses custom threshold' do
      model_id = create_model[:model][:id]
      result   = client.find_situation_boundaries(model_id: model_id, threshold: 0.5)
      expect(result[:threshold]).to eq(0.5)
    end

    it 'detects discontinuity boundary' do
      model_id = create_model[:model][:id]
      client.add_situation_event(model_id: model_id, content: 'high',
                                 space: 0.9, time: 0.9, causation: 0.9, intentionality: 0.9, protagonist: 0.9)
      client.add_situation_event(model_id: model_id, content: 'low',
                                 space: 0.0, time: 0.0, causation: 0.0, intentionality: 0.0, protagonist: 0.0)
      result = client.find_situation_boundaries(model_id: model_id, threshold: 0.3)
      expect(result[:boundaries]).to include(1)
    end
  end

  describe '#situation_dimension_trajectory' do
    it 'returns success: true for known model and dimension' do
      model_id = create_model[:model][:id]
      add_event(model_id, space: 0.7)
      result = client.situation_dimension_trajectory(model_id: model_id, dimension: :space)
      expect(result[:success]).to be(true)
      expect(result[:trajectory]).to be_an(Array)
    end

    it 'accepts string dimensions (converts to symbol)' do
      model_id = create_model[:model][:id]
      add_event(model_id)
      result = client.situation_dimension_trajectory(model_id: model_id, dimension: 'time')
      expect(result[:success]).to be(true)
      expect(result[:dimension]).to eq(:time)
    end

    it 'returns success: false for unknown model' do
      result = client.situation_dimension_trajectory(model_id: 'bad', dimension: :space)
      expect(result[:success]).to be(false)
    end

    it 'tracks trajectory over multiple events' do
      model_id = create_model[:model][:id]
      client.add_situation_event(model_id: model_id, content: 'a',
                                 space: 0.2, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5)
      client.add_situation_event(model_id: model_id, content: 'b',
                                 space: 0.8, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5)
      result = client.situation_dimension_trajectory(model_id: model_id, dimension: :space)
      expect(result[:trajectory]).to eq([0.2, 0.8])
    end
  end

  describe '#most_coherent_situations' do
    it 'returns success: true' do
      result = client.most_coherent_situations
      expect(result[:success]).to be(true)
    end

    it 'returns models array' do
      create_model(label: 'a')
      create_model(label: 'b')
      result = client.most_coherent_situations(limit: 2)
      expect(result[:models]).to be_an(Array)
      expect(result[:count]).to be <= 2
    end

    it 'respects limit' do
      5.times { |i| create_model(label: "m#{i}") }
      result = client.most_coherent_situations(limit: 3)
      expect(result[:models].size).to be <= 3
    end
  end

  describe '#situations_by_label' do
    it 'returns models with matching label' do
      create_model(label: 'target')
      create_model(label: 'target')
      create_model(label: 'other')
      result = client.situations_by_label(label: 'target')
      expect(result[:success]).to be(true)
      expect(result[:count]).to eq(2)
      expect(result[:models].all? { |m| m[:label] == 'target' }).to be(true)
    end

    it 'returns empty for unknown label' do
      result = client.situations_by_label(label: 'unknown')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#update_situation_models' do
    it 'returns success: true' do
      result = client.update_situation_models
      expect(result[:success]).to be(true)
    end

    it 'returns pruned_count' do
      result = client.update_situation_models
      expect(result[:pruned_count]).to be_a(Integer)
    end
  end

  describe '#situation_model_stats' do
    it 'returns success: true' do
      result = client.situation_model_stats
      expect(result[:success]).to be(true)
    end

    it 'includes model_count' do
      create_model
      result = client.situation_model_stats
      expect(result[:model_count]).to be >= 1
    end

    it 'includes models array' do
      result = client.situation_model_stats
      expect(result[:models]).to be_an(Array)
    end
  end
end
