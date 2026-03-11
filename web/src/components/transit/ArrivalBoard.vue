<template>
  <div class="arrival-board">
    <h3 class="board-title">Upcoming Arrivals</h3>
    <p class="stop-name">{{ stopName }}</p>

    <!-- Reliability card — loads independently, hidden when no data -->
    <ReliabilityCard :stop-id="stopId" />

    <LoadingSpinner v-if="loading" size="24px" />

    <p v-else-if="!arrivals.length" class="empty-state">No upcoming arrivals found.</p>

    <ul v-else class="arrival-list">
      <li
        v-for="arrival in arrivals"
        :key="arrival.tripId"
        class="arrival-row"
        :class="arrival.status.toLowerCase()"
      >
        <div class="arrival-route">{{ arrival.routeShortName }}</div>
        <div class="arrival-dest">{{ arrival.headsign }}</div>
        <div class="arrival-time">
          <span v-if="arrival.estimatedArrival">{{ formatTime(arrival.estimatedArrival) }}</span>
          <span v-else>{{ formatTime(arrival.scheduledArrival) }}</span>
          <span v-if="arrival.delaySeconds && arrival.delaySeconds > 60" class="delay-badge">
            +{{ Math.round(arrival.delaySeconds / 60) }}m
          </span>
          <ReliabilityBadge
            v-if="arrival.routeId"
            :stop-id="stopId"
            :route-id="arrival.routeId"
          />
        </div>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import type { Arrival } from '@/types/transit'
import { transitService } from '@/services/transitService'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import ReliabilityCard from './ReliabilityCard.vue'
import ReliabilityBadge from './ReliabilityBadge.vue'

const props = defineProps<{ stopId: string; stopName?: string }>()

const arrivals = ref<Arrival[]>([])
const loading = ref(false)

async function load() {
  if (!props.stopId) return
  loading.value = true
  try {
    arrivals.value = await transitService.getArrivals(props.stopId)
  } finally {
    loading.value = false
  }
}

watch(() => props.stopId, load, { immediate: true })

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}
</script>

<style scoped>
.arrival-board {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1rem;
  min-width: 260px;
}

.board-title {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.25rem;
}

.stop-name {
  font-size: 0.8rem;
  color: var(--color-text-muted);
  margin-bottom: 0.75rem;
}

.empty-state {
  font-size: 0.85rem;
  color: var(--color-text-muted);
  text-align: center;
  padding: 1rem 0;
}

.arrival-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.arrival-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.5rem;
  border-radius: var(--radius-sm);
  background: var(--color-bg);
  font-size: 0.85rem;
}

.arrival-row.delayed .arrival-time {
  color: var(--color-warning);
}

.arrival-route {
  font-weight: 700;
  min-width: 40px;
  color: var(--color-accent);
}

.arrival-dest {
  flex: 1;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.arrival-time {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.delay-badge {
  background: var(--color-warning);
  color: #000;
  padding: 0 0.3rem;
  border-radius: 3px;
  font-size: 0.7rem;
  font-weight: 600;
}
</style>
