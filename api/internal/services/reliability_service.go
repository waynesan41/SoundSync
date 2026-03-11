package services

import (
	"context"
	"database/sql"
	"math"
	"time"
)

// timeBin converts a UTC Unix-ms scheduled arrival time to a Seattle time-of-day bucket.
func timeBin(scheduledMs int64) string {
	loc, _ := time.LoadLocation("America/Los_Angeles")
	t := time.UnixMilli(scheduledMs).In(loc)
	h := t.Hour()
	switch {
	case h >= 6 && h < 9:
		return "morning"
	case h >= 9 && h < 15:
		return "midday"
	case h >= 15 && h < 19:
		return "afternoon"
	default:
		return "evening"
	}
}

// computeScore returns a 0-100 composite reliability index.
//
//	50% on-time rate  (arrivals within ±120 s of schedule)
//	30% consistency   (inverse of delay std-dev, capped at 300 s)
//	20% average delay (inverse of |avg delay|, capped at 600 s)
func computeScore(onTimeRate, avgDelaySec, variance float64) float64 {
	onTimePart := (onTimeRate / 100.0) * 50.0

	stdDev := math.Sqrt(variance)
	consistencyPart := math.Max(0, 1.0-stdDev/300.0) * 30.0

	delayPart := math.Max(0, 1.0-math.Abs(avgDelaySec)/600.0) * 20.0

	return math.Round((onTimePart+consistencyPart+delayPart)*100) / 100
}

// ─── Types ─────────────────────────────────────────────────────────────────

type TimeBinMetrics struct {
	Bin             string  `json:"bin"`
	SampleCount     int     `json:"sample_count"`
	OnTimeRate      float64 `json:"on_time_rate"`
	AvgDelaySeconds float64 `json:"avg_delay_seconds"`
	Score           float64 `json:"score"`
}

type RouteMetrics struct {
	StopID          string           `json:"stop_id"`
	RouteID         string           `json:"route_id"`
	SampleCount     int              `json:"sample_count"`
	OnTimeRate      float64          `json:"on_time_rate"`
	AvgDelaySeconds float64          `json:"avg_delay_seconds"`
	AvgDelayMinutes float64          `json:"avg_delay_minutes"`
	DelayVariance   float64          `json:"delay_variance"`
	Score           float64          `json:"score"`
	TimeOfDay       []TimeBinMetrics `json:"time_of_day"`
}

type StopReliability struct {
	StopID string         `json:"stop_id"`
	Routes []RouteMetrics `json:"routes"`
}

type SummaryEntry struct {
	RouteID         string  `json:"route_id"`
	Score           float64 `json:"score"`
	OnTimeRate      float64 `json:"on_time_rate"`
	AvgDelaySeconds float64 `json:"avg_delay_seconds"`
	SampleCount     int     `json:"sample_count"`
}

type PredictionResult struct {
	StopID              string  `json:"stop_id"`
	RouteID             string  `json:"route_id"`
	TimeBin             string  `json:"time_bin"`
	PredictedDelaySec   float64 `json:"predicted_delay_seconds"`
	PredictedDelayMin   float64 `json:"predicted_delay_minutes"`
	OnTimeRate          float64 `json:"on_time_rate"`
	SampleCount         int     `json:"sample_count"`
}

// ─── Service ───────────────────────────────────────────────────────────────

type ReliabilityService struct {
	pg *sql.DB
}

func NewReliabilityService(pg *sql.DB) *ReliabilityService {
	return &ReliabilityService{pg: pg}
}

// GetStopReliability returns reliability metrics for every route observed at stopID.
func (s *ReliabilityService) GetStopReliability(ctx context.Context, stopID string) (*StopReliability, error) {
	if s.pg == nil {
		return &StopReliability{StopID: stopID, Routes: []RouteMetrics{}}, nil
	}
	routes, err := s.routeMetricsForStop(ctx, stopID, "")
	if err != nil {
		return nil, err
	}
	return &StopReliability{StopID: stopID, Routes: routes}, nil
}

// GetRouteStopReliability returns detailed metrics for one route at one stop.
func (s *ReliabilityService) GetRouteStopReliability(ctx context.Context, stopID, routeID string) (*RouteMetrics, error) {
	if s.pg == nil {
		return &RouteMetrics{StopID: stopID, RouteID: routeID, TimeOfDay: []TimeBinMetrics{}}, nil
	}
	rows, err := s.routeMetricsForStop(ctx, stopID, routeID)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return &RouteMetrics{StopID: stopID, RouteID: routeID, TimeOfDay: []TimeBinMetrics{}}, nil
	}
	return &rows[0], nil
}

// GetSummary returns all tracked routes ranked by reliability score.
func (s *ReliabilityService) GetSummary(ctx context.Context) ([]SummaryEntry, error) {
	if s.pg == nil {
		return []SummaryEntry{}, nil
	}
	const query = `
		SELECT
			route_id,
			COUNT(*)                                                             AS total,
			SUM(CASE WHEN ABS(delay_seconds) <= 120 THEN 1 ELSE 0 END)          AS on_time,
			COALESCE(AVG(delay_seconds::float), 0)                               AS avg_delay,
			COALESCE(VAR_POP(delay_seconds::float), 0)                           AS variance
		FROM arrivals
		GROUP BY route_id
		ORDER BY route_id`

	dbRows, err := s.pg.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer dbRows.Close()

	var results []SummaryEntry
	for dbRows.Next() {
		var routeID string
		var total, onTime int
		var avgDelay, variance float64
		if err := dbRows.Scan(&routeID, &total, &onTime, &avgDelay, &variance); err != nil {
			return nil, err
		}
		onTimeRate := 0.0
		if total > 0 {
			onTimeRate = float64(onTime) / float64(total) * 100.0
		}
		results = append(results, SummaryEntry{
			RouteID:         routeID,
			Score:           computeScore(onTimeRate, avgDelay, variance),
			OnTimeRate:      math.Round(onTimeRate*100) / 100,
			AvgDelaySeconds: math.Round(avgDelay*100) / 100,
			SampleCount:     total,
		})
	}
	if results == nil {
		results = []SummaryEntry{}
	}

	// Sort descending by score
	sortSummary(results)
	return results, nil
}

// GetPrediction returns a predicted delay for the current time-of-day bin.
func (s *ReliabilityService) GetPrediction(ctx context.Context, stopID, routeID string) (*PredictionResult, error) {
	if s.pg == nil {
		return &PredictionResult{StopID: stopID, RouteID: routeID, TimeBin: currentTimeBin()}, nil
	}
	bin := currentTimeBin()

	const query = `
		SELECT
			COUNT(*)                                                             AS sample_count,
			COALESCE(AVG(delay_seconds::float), 0)                               AS predicted_delay,
			CASE WHEN COUNT(*) > 0
				THEN SUM(CASE WHEN ABS(delay_seconds) <= 120 THEN 1 ELSE 0 END)::float / COUNT(*) * 100
				ELSE 0
			END                                                                  AS on_time_rate
		FROM arrivals
		WHERE stop_id = $1
		  AND route_id = $2
		  AND CASE
			WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 6 AND 8  THEN 'morning'
			WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 9 AND 14 THEN 'midday'
			WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 15 AND 18 THEN 'afternoon'
			ELSE 'evening'
		  END = $3`

	row := s.pg.QueryRowContext(ctx, query, stopID, routeID, bin)

	var sampleCount int
	var predictedDelay, onTimeRate float64
	if err := row.Scan(&sampleCount, &predictedDelay, &onTimeRate); err != nil {
		return nil, err
	}

	return &PredictionResult{
		StopID:            stopID,
		RouteID:           routeID,
		TimeBin:           bin,
		PredictedDelaySec: math.Round(predictedDelay*100) / 100,
		PredictedDelayMin: math.Round(predictedDelay/60.0*100) / 100,
		OnTimeRate:        math.Round(onTimeRate*100) / 100,
		SampleCount:       sampleCount,
	}, nil
}

// ─── Internals ─────────────────────────────────────────────────────────────

// routeMetricsForStop fetches aggregate + time-bin stats. If routeID is non-empty,
// results are filtered to that single route.
func (s *ReliabilityService) routeMetricsForStop(ctx context.Context, stopID, routeID string) ([]RouteMetrics, error) {
	// Aggregate query
	aggQuery := `
		SELECT
			route_id,
			COUNT(*)                                                             AS total,
			SUM(CASE WHEN ABS(delay_seconds) <= 120 THEN 1 ELSE 0 END)          AS on_time,
			COALESCE(AVG(delay_seconds::float), 0)                               AS avg_delay,
			COALESCE(VAR_POP(delay_seconds::float), 0)                           AS variance
		FROM arrivals
		WHERE stop_id = $1`
	aggArgs := []any{stopID}
	if routeID != "" {
		aggQuery += " AND route_id = $2"
		aggArgs = append(aggArgs, routeID)
	}
	aggQuery += " GROUP BY route_id ORDER BY route_id"

	aggRows, err := s.pg.QueryContext(ctx, aggQuery, aggArgs...)
	if err != nil {
		return nil, err
	}
	defer aggRows.Close()

	metricsMap := map[string]*RouteMetrics{}
	var order []string
	for aggRows.Next() {
		var rID string
		var total, onTime int
		var avgDelay, variance float64
		if err := aggRows.Scan(&rID, &total, &onTime, &avgDelay, &variance); err != nil {
			return nil, err
		}
		onTimeRate := 0.0
		if total > 0 {
			onTimeRate = float64(onTime) / float64(total) * 100.0
		}
		metricsMap[rID] = &RouteMetrics{
			StopID:          stopID,
			RouteID:         rID,
			SampleCount:     total,
			OnTimeRate:      math.Round(onTimeRate*100) / 100,
			AvgDelaySeconds: math.Round(avgDelay*100) / 100,
			AvgDelayMinutes: math.Round(avgDelay/60.0*100) / 100,
			DelayVariance:   math.Round(variance*100) / 100,
			Score:           computeScore(onTimeRate, avgDelay, variance),
			TimeOfDay:       []TimeBinMetrics{},
		}
		order = append(order, rID)
	}

	if len(order) == 0 {
		return []RouteMetrics{}, nil
	}

	// Time-bin breakdown query
	binQuery := `
		SELECT
			route_id,
			CASE
				WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 6  AND 8  THEN 'morning'
				WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 9  AND 14 THEN 'midday'
				WHEN EXTRACT(HOUR FROM to_timestamp(scheduled_arrival/1000.0) AT TIME ZONE 'America/Los_Angeles') BETWEEN 15 AND 18 THEN 'afternoon'
				ELSE 'evening'
			END                                                                  AS time_bin,
			COUNT(*)                                                             AS total,
			SUM(CASE WHEN ABS(delay_seconds) <= 120 THEN 1 ELSE 0 END)          AS on_time,
			COALESCE(AVG(delay_seconds::float), 0)                               AS avg_delay,
			COALESCE(VAR_POP(delay_seconds::float), 0)                           AS variance
		FROM arrivals
		WHERE stop_id = $1`
	binArgs := []any{stopID}
	if routeID != "" {
		binQuery += " AND route_id = $2"
		binArgs = append(binArgs, routeID)
	}
	binQuery += " GROUP BY route_id, time_bin ORDER BY route_id, time_bin"

	binRows, err := s.pg.QueryContext(ctx, binQuery, binArgs...)
	if err != nil {
		return nil, err
	}
	defer binRows.Close()

	for binRows.Next() {
		var rID, bin string
		var total, onTime int
		var avgDelay, variance float64
		if err := binRows.Scan(&rID, &bin, &total, &onTime, &avgDelay, &variance); err != nil {
			return nil, err
		}
		m, ok := metricsMap[rID]
		if !ok {
			continue
		}
		onTimeRate := 0.0
		if total > 0 {
			onTimeRate = float64(onTime) / float64(total) * 100.0
		}
		m.TimeOfDay = append(m.TimeOfDay, TimeBinMetrics{
			Bin:             bin,
			SampleCount:     total,
			OnTimeRate:      math.Round(onTimeRate*100) / 100,
			AvgDelaySeconds: math.Round(avgDelay*100) / 100,
			Score:           computeScore(onTimeRate, avgDelay, variance),
		})
	}

	result := make([]RouteMetrics, 0, len(order))
	for _, id := range order {
		result = append(result, *metricsMap[id])
	}
	return result, nil
}

func currentTimeBin() string {
	loc, _ := time.LoadLocation("America/Los_Angeles")
	h := time.Now().In(loc).Hour()
	switch {
	case h >= 6 && h < 9:
		return "morning"
	case h >= 9 && h < 15:
		return "midday"
	case h >= 15 && h < 19:
		return "afternoon"
	default:
		return "evening"
	}
}

// sortSummary sorts in-place by score descending (insertion sort — small slice).
func sortSummary(s []SummaryEntry) {
	for i := 1; i < len(s); i++ {
		key := s[i]
		j := i - 1
		for j >= 0 && s[j].Score < key.Score {
			s[j+1] = s[j]
			j--
		}
		s[j+1] = key
	}
}
