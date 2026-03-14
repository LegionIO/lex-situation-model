# lex-situation-model

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-situation-model`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::SituationModel`

## Purpose

Implements a five-dimension situation model inspired by Zwaan & Radvansky's situational indexing framework. Each situation tracks events scored across five dimensions — space, time, causation, intentionality, and protagonist. Events within a situation are compared for continuity; sharp drops in continuity mark event boundaries (situation shifts). Supports coherence scoring, dimension trajectory tracking, and health classification.

## Gem Info

- **Gem name**: `lex-situation-model`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/situation_model/
  version.rb                          # VERSION = '0.1.0'
  helpers/
    constants.rb                      # DIMENSIONS, CONTINUITY_LABELS, MODEL_HEALTH_LABELS, limits, DECAY_RATE
    situation_event.rb                # SituationEvent class — single event with 5-dimension scores
    situation_model.rb                # SituationModel class — event sequence with coherence tracking
    situation_engine.rb               # SituationEngine class — store of SituationModel objects
  runners/
    situation_model.rb                # Runners::SituationModel module — all public runner methods
  client.rb                           # Client class including Runners::SituationModel
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `DIMENSIONS` | 5 symbols | `:space`, `:time`, `:causation`, `:intentionality`, `:protagonist` |
| `CONTINUITY_LABELS` | hash | Named tiers: high/moderate/low/discontinuous based on continuity score |
| `MODEL_HEALTH_LABELS` | hash | Named tiers: stable/degrading/fragmented based on coherence |
| `MAX_MODELS` | 100 | Maximum situation models |
| `MAX_EVENTS_PER_MODEL` | 200 | Maximum events per model |
| `DECAY_RATE` | 0.01 | Coherence decrease per `decay!` cycle |

## Helpers

### `Helpers::SituationEvent`

Single event scored across the five situation dimensions.

- `initialize(id:, description:, dimension_values: {})` — clamps each dimension value to 0.0–1.0; defaults missing dimensions to 0.5
- `continuity_with(other)` — `1.0 - avg_diff` where avg_diff is the mean absolute difference across all 5 dimensions between self and `other`
- `discontinuous_dimensions(other, threshold: 0.3)` — returns dimension names where difference exceeds threshold

### `Helpers::SituationModel`

Ordered event sequence with coherence tracking.

- `initialize(id:, name:, domain: :general)` — empty events array, coherence = 1.0
- `add_event(description:, dimension_values: {})` — creates SituationEvent, appends to events; returns continuity score with previous event (1.0 if first event)
- `coherence` — mean pairwise continuity across consecutive event pairs; returns 1.0 if fewer than 2 events
- `health_label` — maps coherence to MODEL_HEALTH_LABELS
- `dominant_dimension` — dimension with the highest average value across all events
- `weakest_dimension` — dimension with the lowest average value
- `event_boundaries(threshold: 0.4)` — returns indices where continuity with previous event drops below threshold
- `dimension_trajectory(dimension)` — array of that dimension's values across events in order
- `decay!` — decrements coherence by DECAY_RATE; floors at 0.0

### `Helpers::SituationEngine`

Store of SituationModel objects.

- `initialize` — empty models hash
- `create(name:, domain: :general)` — returns nil if at MAX_MODELS
- `add_event(model_id:, description:, dimension_values: {})` — delegates to `model.add_event`
- `coherence_for(model_id)` — returns model's coherence score
- `boundaries_for(model_id, threshold: 0.4)` — returns event boundary indices
- `trajectory_for(model_id:, dimension:)` — returns dimension values across events
- `most_coherent(limit: 5)` — sorted by coherence descending
- `by_health_label(label)` — filters models by health label
- `decay_all` — calls `decay!` on all models

## Runners

All runners are in `Runners::SituationModel`. The `Client` includes this module and owns a `SituationEngine` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `create_situation_model` | `name:, domain: :general` | `{ success:, model_id:, name:, domain: }` |
| `add_situation_event` | `model_id:, description:, space: 0.5, time: 0.5, causation: 0.5, intentionality: 0.5, protagonist: 0.5` | `{ success:, model_id:, event_id:, continuity: }` |
| `situation_model_coherence` | `model_id:` | `{ success:, model_id:, coherence:, health_label: }` |
| `find_situation_boundaries` | `model_id:, threshold: 0.4` | `{ success:, model_id:, boundaries:, count: }` |
| `situation_dimension_trajectory` | `model_id:, dimension:` | `{ success:, model_id:, dimension:, trajectory: }` |
| `most_coherent_situations` | `limit: 5` | `{ success:, situations:, count: }` |
| `situations_by_label` | `label:` | `{ success:, situations:, count: }` |
| `update_situation_models` | (none) | `{ success:, models: }` — calls `decay_all` |
| `situation_model_stats` | (none) | Engine summary: total models, mean coherence, health distribution |

## Integration Points

- **lex-tick / lex-cortex**: `update_situation_models` wired as a tick handler runs the decay cycle; `add_situation_event` can be called from the `sensory_processing` or `memory_retrieval` phases to track the evolving situation
- **lex-memory**: memory traces provide the raw events that populate situation models; high-continuity traces are likely part of the same situation
- **lex-temporal**: temporal dimension values should be coordinated with lex-temporal's perception of elapsed time
- **lex-narrative** (future): situation models provide the structured substrate for narrative generation
- **lex-dream**: situation coherence tracking during dream cycles helps identify contradictions across situations

## Development Notes

- `continuity_with` is symmetric; the score is purely dimensional proximity, not semantic meaning
- `event_boundaries` uses a configurable threshold — default 0.4 means a 40% average dimension shift triggers a boundary
- `dimension_trajectory` returns raw float arrays for downstream plotting or pattern analysis
- `coherence` is recomputed on each call from the current events list — it is not memoized
- `decay!` degrades the stored coherence score directly, separate from the recomputed value — this models memory degradation of a situation's overall coherence over time
