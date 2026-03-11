<template>
  <span
    v-if="score !== null"
    class="reliability-badge"
    :style="{ '--badge-color': color }"
    :title="`Reliability score: ${score}/100`"
  >
    {{ score }}
  </span>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { reliabilityService } from '@/services/reliabilityService'

const props = defineProps<{ stopId: string; routeId: string }>()

const score = ref<number | null>(null)

const color = ref('var(--color-text-muted)')

function scoreColor(s: number): string {
  if (s >= 80) return 'var(--color-success)'
  if (s >= 50) return 'var(--color-warning)'
  return 'var(--color-danger)'
}

async function load() {
  try {
    const result = await reliabilityService.getRouteReliability(props.stopId, props.routeId)
    if (result.sample_count > 0) {
      score.value = Math.round(result.score)
      color.value = scoreColor(result.score)
    }
  } catch {
    // no data — badge stays hidden
  }
}

watch([() => props.stopId, () => props.routeId], load, { immediate: true })
</script>

<style scoped>
.reliability-badge {
  display: inline-block;
  padding: 0 0.3rem;
  border-radius: 3px;
  font-size: 0.68rem;
  font-weight: 700;
  border: 1px solid var(--badge-color);
  color: var(--badge-color);
  background: color-mix(in srgb, var(--badge-color) 15%, transparent);
  line-height: 1.4;
}
</style>
