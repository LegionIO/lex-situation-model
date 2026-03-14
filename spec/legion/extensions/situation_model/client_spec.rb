# frozen_string_literal: true

require 'legion/extensions/situation_model/client'

RSpec.describe Legion::Extensions::SituationModel::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    %i[
      create_situation_model
      add_situation_event
      situation_model_coherence
      find_situation_boundaries
      situation_dimension_trajectory
      most_coherent_situations
      situations_by_label
      update_situation_models
      situation_model_stats
    ].each do |method_name|
      expect(client).to respond_to(method_name)
    end
  end

  it 'round-trips a full situation model lifecycle' do
    created  = client.create_situation_model(label: 'round_trip')
    model_id = created[:model][:id]

    client.add_situation_event(model_id: model_id, content: 'scene 1',
                               space: 0.8, time: 0.8, causation: 0.8, intentionality: 0.7, protagonist: 0.9)
    client.add_situation_event(model_id: model_id, content: 'scene 2',
                               space: 0.7, time: 0.9, causation: 0.8, intentionality: 0.7, protagonist: 0.8)

    coh = client.situation_model_coherence(model_id: model_id)
    expect(coh[:success]).to be(true)
    expect(coh[:coherence]).to be > 0.7

    traj = client.situation_dimension_trajectory(model_id: model_id, dimension: :time)
    expect(traj[:trajectory]).to eq([0.8, 0.9])

    stats = client.situation_model_stats
    expect(stats[:model_count]).to be >= 1
  end

  it 'maintains separate engine state per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_situation_model(label: 'only_c1')
    expect(c1.situation_model_stats[:model_count]).to eq(1)
    expect(c2.situation_model_stats[:model_count]).to eq(0)
  end
end
