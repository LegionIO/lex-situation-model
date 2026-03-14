# frozen_string_literal: true

RSpec.describe Legion::Extensions::SituationModel::Helpers::Constants do
  it 'defines 5 dimensions' do
    expect(described_class::DIMENSIONS.size).to eq(5)
    expect(described_class::DIMENSIONS).to include(:space, :time, :causation, :intentionality, :protagonist)
  end

  it 'CONTINUITY_LABELS covers the full 0..1 range' do
    [0.0, 0.1, 0.2, 0.3, 0.5, 0.6, 0.8, 0.9, 1.0].each do |v|
      match = described_class::CONTINUITY_LABELS.find { |range, _| range.cover?(v) }
      expect(match).not_to be_nil, "no label for #{v}"
    end
  end

  it 'assigns :rupture for very low continuity' do
    label = described_class::CONTINUITY_LABELS.find { |r, _| r.cover?(0.1) }&.last
    expect(label).to eq(:rupture)
  end

  it 'assigns :continuous for high continuity' do
    label = described_class::CONTINUITY_LABELS.find { |r, _| r.cover?(0.9) }&.last
    expect(label).to eq(:continuous)
  end

  it 'assigns :shift for mid-range continuity' do
    label = described_class::CONTINUITY_LABELS.find { |r, _| r.cover?(0.6) }&.last
    expect(label).to eq(:shift)
  end

  it 'MODEL_HEALTH_LABELS covers full range' do
    [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1.0].each do |v|
      match = described_class::MODEL_HEALTH_LABELS.find { |range, _| range.cover?(v) }
      expect(match).not_to be_nil, "no health label for #{v}"
    end
  end

  it 'assigns :vivid for coherence >= 0.8' do
    label = described_class::MODEL_HEALTH_LABELS.find { |r, _| r.cover?(0.85) }&.last
    expect(label).to eq(:vivid)
  end

  it 'assigns :collapsed for coherence <= 0.2' do
    label = described_class::MODEL_HEALTH_LABELS.find { |r, _| r.cover?(0.05) }&.last
    expect(label).to eq(:collapsed)
  end

  it 'has sensible numeric constants' do
    expect(described_class::MAX_MODELS).to eq(100)
    expect(described_class::MAX_EVENTS_PER_MODEL).to eq(200)
    expect(described_class::DECAY_RATE).to eq(0.01)
    expect(described_class::DEFAULT_DIMENSION_VALUE).to eq(0.5)
    expect(described_class::COHERENCE_FLOOR).to eq(0.0)
    expect(described_class::COHERENCE_CEILING).to eq(1.0)
  end
end
