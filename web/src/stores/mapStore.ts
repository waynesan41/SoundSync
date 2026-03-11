import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { VehiclePosition, Stop, LatLng } from '@/types/transit'
import { transitService } from '@/services/transitService'

const POLL_INTERVAL_MS = 15_000

export const useMapStore = defineStore('map', () => {
  const vehicles = ref<VehiclePosition[]>([])
  const center = ref<LatLng>({ lat: 47.6062, lng: -122.3321 }) // Seattle
  const zoom = ref(12)
  const selectedVehicleId = ref<string | null>(null)
  const selectedStop = ref<Stop | null>(null)
  const nearbyStops = ref<Stop[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const showOnlyPlanned = ref(false)

  let pollTimer: ReturnType<typeof setInterval> | null = null

  async function fetchVehicles() {
    try {
      isLoading.value = true
      error.value = null
      vehicles.value = await transitService.getVehicles()
    } catch (e) {
      error.value = 'Failed to load vehicle positions'
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchNearbyStops(lat: number, lng: number, radius = 500) {
    try {
      nearbyStops.value = await transitService.getNearbyStops(lat, lng, radius)
    } catch {
      // silently skip — stops are optional UI
    }
  }

  function startPolling() {
    fetchVehicles()
    pollTimer = setInterval(fetchVehicles, POLL_INTERVAL_MS)
  }

  function stopPolling() {
    if (pollTimer !== null) {
      clearInterval(pollTimer)
      pollTimer = null
    }
  }

  function selectVehicle(vehicleId: string | null) {
    selectedVehicleId.value = vehicleId
  }

  function selectStop(stop: Stop | null) {
    selectedStop.value = stop
  }

  function setCenter(latLng: LatLng, newZoom?: number) {
    center.value = latLng
    if (newZoom !== undefined) zoom.value = newZoom
  }

  return {
    vehicles,
    center,
    zoom,
    selectedVehicleId,
    selectedStop,
    nearbyStops,
    isLoading,
    error,
    showOnlyPlanned,
    fetchVehicles,
    fetchNearbyStops,
    startPolling,
    stopPolling,
    selectVehicle,
    selectStop,
    setCenter,
  }
})
