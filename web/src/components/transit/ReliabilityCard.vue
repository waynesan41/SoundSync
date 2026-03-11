<template>
  <div v-if="!loading && hasData" class="reliability-card">
    <!-- Header -->
    <div class="card-header">
      <span class="header-icon">📊</span>
      <span class="header-title">Reliability</span>
      <span class="header-sub">{{ routes.length }} route{{ routes.length !== 1 ? 's' : '' }}</span>
    </div>

    <!-- Route selector tabs (when multiple routes) -->
    <div v-if="routes.length > 1" class="route-tabs">
      <button
        v-for="r in routes"
        :key="r.route_id"
        class="route-tab"
        :class="{ active: selectedRouteId === r.route_id }"
        :style="{ '--tab-color': scoreColor(r.score) }"
        @click="selectedRouteId = r.route_id"
      >
        {{ r.route_id }}
      </button>
    </div>

    <!-- Score row -->
    <div v-if="selected" class="score-row">
      <!-- Gauge circle -->
      <div class="gauge" :style="{ '--gauge-color': scoreColor(selected.score) }">
        <span class="gauge-value">{{ Math.round(selected.score) }}</span>
      </div>

      <!-- Stats -->
      <div class="stats">
        <span class="score-label" :style="{ color: scoreColor(selected.score) }">
          {{ scoreLabel(selected.score) }}
        </span>
        <div class="stat-chips">
          <div class="chip">
            <span class="chip-value">{{ Math.round(selected.on_time_rate) }}%</span>
            <span class="chip-label">on-time</span>
          </div>
          <div class="chip" :class="{ warn: Math.abs(selected.avg_delay_minutes) > 2 }">
            <span class="chip-value">{{ formatDelay(selected.avg_delay_minutes) }}</span>
            <span class="chip-label">avg delay</span>
          </div>
          <div v-if="selected.sample_count > 0" class="chip">
            <span class="chip-value">{{ selected.sample_count }}</span>
            <span class="chip-label">samples</span>
          </div>
        </div>

        <!-- Live prediction for current time bin -->
        <div v-if="prediction && prediction.sample_count > 0" class="prediction-row">
          <span class="pred-icon">🔮</span>
          <span class="pred-text">
            Now ({{ prediction.time_bin }}):
            <strong>{{ formatDelay(prediction.predicted_delay_minutes) }}</strong> expected
          </span>
        </div>
      </div>
    </div>

    <!-- Time-of-day breakdown -->
    <div v-if="selected && selected.time_of_day.length > 0" class="time-breakdown">
      <p class="breakdown-title">Best time to travel</p>
      <div class="bins">
        <div
          v-for="bin in BIN_ORDER"
          :key="bin"
          class="bin-cell"
        >
          <div class="bin-bar-track">
            <div
              class="bin-bar-fill"
              :style="{
                height: binMetrics(bin) ? `${binMetrics(bin)!.score}%` : '0%',
                background: binMetrics(bin) ? scoreColor(binMetrics(bin)!.score) : 'var(--color-border)',
              }"
            />
          </div>
          <span
            class="bin-score"
            :style="{ color: binMetrics(bin) ? scoreColor(binMetrics(bin)!.score) : 'var(--color-text-muted)' }"
          >
            {{ binMetrics(bin) ? Math.round(binMetrics(bin)!.score) : '—' }}
          </span>
          <span class="bin-label">{{ BIN_LABELS[bin] }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { reliabilityService, type RouteMetrics, type PredictionResult, type TimeBinMetrics } from '@/services/reliabilityService'

const props = defineProps<{ stopId: string }>()

const loading = ref(false)
const routes = ref<RouteMetrics[]>([])
const selectedRouteId = ref<string | null>(null)
const prediction = ref<PredictionResult | null>(null)

const BIN_ORDER = ['morning', 'midday', 'afternoon', 'evening'] as const
const BIN_LABELS: Record<string, string> = {
  morning: 'Morning\n6–9am',
  midday: 'Midday\n9am–3pm',
  afternoon: 'Afternoon\n3–7pm',
  evening: 'Evening\n7pm+',
}

const hasData = computed(() => routes.value.length > 0)

const selected = computed<RouteMetrics | null>(() =>
  routes.value.find(r => r.route_id === selectedRouteId.value) ?? routes.value[0] ?? null,
)

function binMetrics(bin: string): TimeBinMetrics | undefined {
  return selected.value?.time_of_day.find(t => t.bin === bin)
}

function scoreColor(score: number): string {
  if (score >= 80) return 'var(--color-success)'   // green
  if (score >= 50) return 'var(--color-warning)'   // amber
  return 'var(--color-danger)'                      // red
}

function scoreLabel(score: number): string {
  if (score >= 80) return 'Reliable'
  if (score >= 50) return 'Fair'
  return 'Unreliable'
}

function formatDelay(minutes: number): string {
  if (Math.abs(minutes) < 0.5) return 'On time'
  const sign = minutes > 0 ? '+' : ''
  if (Math.abs(minutes) < 1) return `${sign}${Math.round(minutes * 60)}s`
  return `${sign}${minutes.toFixed(1)} min`
}

async function loadPrediction(routeId: string) {
  prediction.value = null
  try {
    const result = await reliabilityService.getPrediction(props.stopId, routeId)
    prediction.value = result
  } catch {
    // poller may not have data yet — silently skip
  }
}

watch(selected, (r) => {
  if (r) loadPrediction(r.route_id)
})

async function load(stopId: string) {
  if (!stopId) return
  loading.value = true
  try {
    const result = await reliabilityService.getStopReliability(stopId)
    routes.value = result.routes
    if (result.routes.length > 0) {
      selectedRouteId.value = result.routes[0].route_id
    }
  } catch {
    // API not available — render nothing
  } finally {
    loading.value = false
  }
}

watch(() => props.stopId, load, { immediate: true })
</script>

<style scoped>
.reliability-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 0.875rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

/* ── Header ── */
.card-header {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.header-icon { font-size: 0.9rem; }

.header-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text);
}

.header-sub {
  margin-left: auto;
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* ── Route tabs ── */
.route-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
}

.route-tab {
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  border: 1px solid var(--color-border);
  background: var(--color-bg);
  color: var(--color-text-muted);
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.route-tab.active {
  border-color: var(--tab-color);
  color: var(--tab-color);
  background: color-mix(in srgb, var(--tab-color) 15%, transparent);
}

/* ── Score row ── */
.score-row {
  display: flex;
  align-items: flex-start;
  gap: 0.875rem;
}

.gauge {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  border: 2px solid var(--gauge-color);
  background: color-mix(in srgb, var(--gauge-color) 12%, transparent);
  display: flex;
  align-items: center;
  justify-content: center;
}

.gauge-value {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--gauge-color);
}

.stats {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.score-label {
  font-size: 0.9rem;
  font-weight: 700;
}

.stat-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.3rem;
}

.chip {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: var(--color-bg);
  border-radius: var(--radius-sm);
  padding: 0.2rem 0.5rem;
  min-width: 48px;
}

.chip.warn .chip-value {
  color: var(--color-warning);
}

.chip-value {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--color-text);
}

.chip-label {
  font-size: 0.65rem;
  color: var(--color-text-muted);
}

/* ── Prediction row ── */
.prediction-row {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.75rem;
  color: var(--color-accent);
}

.pred-icon { font-size: 0.8rem; }

/* ── Time breakdown ── */
.time-breakdown {
  border-top: 1px solid var(--color-border);
  padding-top: 0.65rem;
}

.breakdown-title {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.5rem;
}

.bins {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.3rem;
  align-items: end;
}

.bin-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.2rem;
}

.bin-bar-track {
  width: 100%;
  height: 40px;
  background: var(--color-bg);
  border-radius: 3px;
  display: flex;
  align-items: flex-end;
  overflow: hidden;
}

.bin-bar-fill {
  width: 100%;
  border-radius: 3px;
  transition: height 0.4s ease;
  min-height: 2px;
}

.bin-score {
  font-size: 0.75rem;
  font-weight: 700;
  line-height: 1;
}

.bin-label {
  font-size: 0.62rem;
  color: var(--color-text-muted);
  text-align: center;
  white-space: pre-line;
  line-height: 1.2;
}
</style>
