import api from './api'

// ─── Types ────────────────────────────────────────────────────────────────────

export interface TimeBinMetrics {
  bin: 'morning' | 'midday' | 'afternoon' | 'evening'
  sample_count: number
  on_time_rate: number
  avg_delay_seconds: number
  score: number
}

export interface RouteMetrics {
  stop_id: string
  route_id: string
  sample_count: number
  on_time_rate: number
  avg_delay_seconds: number
  avg_delay_minutes: number
  delay_variance: number
  score: number
  time_of_day: TimeBinMetrics[]
}

export interface StopReliability {
  stop_id: string
  routes: RouteMetrics[]
}

export interface PredictionResult {
  stop_id: string
  route_id: string
  time_bin: string
  predicted_delay_seconds: number
  predicted_delay_minutes: number
  on_time_rate: number
  sample_count: number
}

export interface SummaryEntry {
  route_id: string
  score: number
  on_time_rate: number
  avg_delay_seconds: number
  sample_count: number
}

// ─── Service ──────────────────────────────────────────────────────────────────

export const reliabilityService = {
  async getStopReliability(stopId: string): Promise<StopReliability> {
    const { data } = await api.get(`/reliability/${encodeURIComponent(stopId)}`)
    return data.data as StopReliability
  },

  async getRouteReliability(stopId: string, routeId: string): Promise<RouteMetrics> {
    const { data } = await api.get(
      `/reliability/${encodeURIComponent(stopId)}/${encodeURIComponent(routeId)}`,
    )
    return data.data as RouteMetrics
  },

  async getSummary(): Promise<SummaryEntry[]> {
    const { data } = await api.get('/reliability/summary')
    return data.data.routes as SummaryEntry[]
  },

  async getPrediction(stopId: string, routeId: string): Promise<PredictionResult> {
    const { data } = await api.get(
      `/prediction/${encodeURIComponent(stopId)}/${encodeURIComponent(routeId)}`,
    )
    return data.data as PredictionResult
  },
}
