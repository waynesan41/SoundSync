<template>
  <div class="home-view">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-top">
        <WeatherWidget />
      </div>
      <RouteSearchPanel />

      <!-- Stop panel — shown when a stop is selected on the map -->
      <div v-if="mapStore.selectedStop" class="stop-panel">
        <div class="stop-panel-header">
          <span class="stop-icon">🚏</span>
          <span class="stop-name">{{ mapStore.selectedStop.name }}</span>
          <button class="stop-close" @click="mapStore.selectStop(null)">✕</button>
        </div>
        <ArrivalBoard
          :stop-id="mapStore.selectedStop.stopId"
          :stop-name="mapStore.selectedStop.name"
        />
      </div>
    </aside>

    <!-- Map fills remaining space -->
    <div class="map-area">
      <MapContainer />
    </div>
  </div>
</template>

<script setup lang="ts">
import MapContainer from '@/components/map/MapContainer.vue'
import RouteSearchPanel from '@/components/transit/RouteSearchPanel.vue'
import WeatherWidget from '@/components/weather/WeatherWidget.vue'
import ArrivalBoard from '@/components/transit/ArrivalBoard.vue'
import { useMapStore } from '@/stores/mapStore'

const mapStore = useMapStore()
</script>

<style scoped>
.home-view {
  display: flex;
  height: 100%;
  overflow: hidden;
}

.sidebar {
  width: 380px;
  flex-shrink: 0;
  background: var(--color-bg);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  overflow-y: auto;
}

.sidebar-top {
  display: flex;
  justify-content: flex-end;
}

.map-area {
  flex: 1;
  position: relative;
  overflow: hidden;
}

/* ── Stop panel ── */
.stop-panel {
  border-top: 1px solid var(--color-border);
  padding-top: 0.75rem;
}

.stop-panel-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.stop-icon {
  font-size: 1rem;
}

.stop-name {
  flex: 1;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stop-close {
  background: none;
  border: none;
  color: var(--color-text-muted);
  font-size: 0.85rem;
  cursor: pointer;
  padding: 0.1rem 0.3rem;
  border-radius: 4px;
  transition: color 0.15s;
}

.stop-close:hover {
  color: var(--color-text);
}
</style>
