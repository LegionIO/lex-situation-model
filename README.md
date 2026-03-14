# lex-situation-model

Five-dimension situation tracking for LegionIO cognitive agents. Models narrative coherence and event boundaries using Zwaan & Radvansky's situational indexing dimensions.

## What It Does

`lex-situation-model` tracks sequences of events scored across five dimensions — space, time, causation, intentionality, and protagonist. Events within a situation are compared pairwise for continuity; sharp discontinuities mark situation boundaries (the cognitive equivalent of a scene change). Situations are scored for overall coherence and can be ranked by health.

- **Dimensions**: `:space`, `:time`, `:causation`, `:intentionality`, `:protagonist` (each 0.0–1.0)
- **Continuity**: `1.0 - mean_dimension_diff` between consecutive events (1.0 = identical, 0.0 = completely different)
- **Event boundaries**: indices where continuity drops below a configurable threshold (default 0.4)
- **Coherence**: mean pairwise continuity across the full event sequence
- **Health labels**: `:stable` (coherent), `:degrading`, `:fragmented`
- **Decay**: coherence degrades passively each tick

## Usage

```ruby
require 'legion/extensions/situation_model'

client = Legion::Extensions::SituationModel::Client.new

# Create a situation
result = client.create_situation_model(name: 'office_meeting', domain: :work)
model_id = result[:model_id]

# Add events with dimension scores
client.add_situation_event(
  model_id: model_id,
  description: 'team arrives',
  space: 0.8, time: 0.2, causation: 0.5, intentionality: 0.7, protagonist: 0.9
)
# => { continuity: 1.0 }  (first event)

client.add_situation_event(
  model_id: model_id,
  description: 'discussion begins',
  space: 0.8, time: 0.3, causation: 0.6, intentionality: 0.8, protagonist: 0.9
)
# => { continuity: 0.94 }  (high — same space, same protagonists)

client.add_situation_event(
  model_id: model_id,
  description: 'unexpected fire alarm',
  space: 0.1, time: 0.3, causation: 0.1, intentionality: 0.1, protagonist: 0.5
)
# => { continuity: 0.42 }  (low — space and intentionality shifted sharply)

# Check overall coherence
client.situation_model_coherence(model_id: model_id)
# => { coherence: 0.71, health_label: :stable }

# Find event boundaries
client.find_situation_boundaries(model_id: model_id, threshold: 0.4)
# => { boundaries: [2], count: 1 }

# Trace how time dimension evolved
client.situation_dimension_trajectory(model_id: model_id, dimension: :time)
# => { trajectory: [0.2, 0.3, 0.3] }

# Per-tick decay
client.update_situation_models
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
