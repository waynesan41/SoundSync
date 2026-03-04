package arrivals

import (
	"fmt"
	"math"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"soundsync/backend/internal/db"
)

// safeIDPattern allows only characters that are safe to embed directly in SQL
// string literals without quoting (route IDs and stop IDs are always like
// "100001" or "1_67652" in the OBA data set).
var safeIDPattern = regexp.MustCompile(`^[a-zA-Z0-9_\-]+$`)

func safeID(s string) bool {
	return s == "" || safeIDPattern.MatchString(s)
}

// Arrival is one row from the PostgreSQL arrivals table.
type Arrival struct {
	ID                int    `json:"id"`
	StopID            string `json:"stop_id"`
	RouteID           string `json:"route_id"`
	TripID            string `json:"trip_id"`
	Headsign          string `json:"headsign"`
	ScheduledArrival  int64  `json:"scheduled_arrival_ms"`
	PredictedArrival  int64  `json:"predicted_arrival_ms"`
	DelaySeconds      int    `json:"delay_seconds"`
	RecordedAt        string `json:"recorded_at"`
}

// TimeBinStats holds aggregated delay statistics for one time-bin/day-type bucket.
type TimeBinStats struct {
	TimeBin        string  `json:"time_bin"`
	DayType        string  `json:"day_type"`
	SampleCount    int     `json:"sample_count"`
	AvgDelaySeconds  float64 `json:"avg_delay_seconds"`
	P90DelaySeconds  float64 `json:"p90_delay_seconds"`
}

// ArrivalStats is the full stats response for a route/stop.
type ArrivalStats struct {
	RouteID            string         `json:"route_id"`
	StopID             string         `json:"stop_id"`
	TotalSamples       int            `json:"total_samples"`
	OverallAvgDelaySeconds float64    `json:"overall_avg_delay_seconds"`
	ByTimeBin          []TimeBinStats `json:"by_time_bin"`
}

// Service queries the PostgreSQL arrivals table written by the transit poller.
type Service struct {
	cfg db.PGConfig
}

// NewService creates an arrivals Service with the given connection config.
func NewService(cfg db.PGConfig) *Service {
	return &Service{cfg: cfg}
}

// List returns recent arrivals filtered by routeID and/or stopID.
// Results are sorted newest-first; limit is capped at 200.
func (s *Service) List(routeID, stopID string, limit int) ([]Arrival, error) {
	if !safeID(routeID) || !safeID(stopID) {
		return nil, fmt.Errorf("routeId and stopId must be alphanumeric")
	}
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}

	var clauses []string
	if routeID != "" {
		clauses = append(clauses, "route_id = '"+routeID+"'")
	}
	if stopID != "" {
		clauses = append(clauses, "stop_id = '"+stopID+"'")
	}

	query := "SELECT id, stop_id, route_id, trip_id, headsign, " +
		"scheduled_arrival, predicted_arrival, delay_seconds, recorded_at " +
		"FROM arrivals"
	if len(clauses) > 0 {
		query += " WHERE " + strings.Join(clauses, " AND ")
	}
	query += " ORDER BY recorded_at DESC LIMIT " + strconv.Itoa(limit)

	conn, err := db.ConnectPostgres(s.cfg)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	rows, err := conn.Query(query)
	if err != nil {
		return nil, err
	}

	// Build column-name → index map so we're resilient to column order changes.
	colIdx := make(map[string]int, len(rows.Columns))
	for i, c := range rows.Columns {
		colIdx[c] = i
	}

	var out []Arrival
	for rows.Next() {
		vals := rows.Values()
		a := Arrival{
			StopID:   colVal(vals, colIdx, "stop_id"),
			RouteID:  colVal(vals, colIdx, "route_id"),
			TripID:   colVal(vals, colIdx, "trip_id"),
			Headsign: colVal(vals, colIdx, "headsign"),
			RecordedAt: colVal(vals, colIdx, "recorded_at"),
		}
		a.ID, _ = strconv.Atoi(colVal(vals, colIdx, "id"))
		a.ScheduledArrival, _ = strconv.ParseInt(colVal(vals, colIdx, "scheduled_arrival"), 10, 64)
		a.PredictedArrival, _ = strconv.ParseInt(colVal(vals, colIdx, "predicted_arrival"), 10, 64)
		a.DelaySeconds, _ = strconv.Atoi(colVal(vals, colIdx, "delay_seconds"))
		out = append(out, a)
	}
	return out, nil
}

// Stats returns aggregated delay statistics for a route/stop over the last
// 90 days, broken down by time-of-day bin and day type (weekday/weekend).
// routeID is required; stopID is optional.
func (s *Service) Stats(routeID, stopID string) (ArrivalStats, error) {
	if !safeID(routeID) || !safeID(stopID) {
		return ArrivalStats{}, fmt.Errorf("routeId and stopId must be alphanumeric")
	}

	since := time.Now().UTC().AddDate(0, 0, -90).Format("2006-01-02 15:04:05")

	var clauses []string
	clauses = append(clauses, "recorded_at >= '"+since+"'")
	if routeID != "" {
		clauses = append(clauses, "route_id = '"+routeID+"'")
	}
	if stopID != "" {
		clauses = append(clauses, "stop_id = '"+stopID+"'")
	}

	query := "SELECT delay_seconds, recorded_at FROM arrivals WHERE " +
		strings.Join(clauses, " AND ") +
		" ORDER BY recorded_at DESC"

	conn, err := db.ConnectPostgres(s.cfg)
	if err != nil {
		return ArrivalStats{}, err
	}
	defer conn.Close()

	rows, err := conn.Query(query)
	if err != nil {
		return ArrivalStats{}, err
	}

	colIdx := make(map[string]int, len(rows.Columns))
	for i, c := range rows.Columns {
		colIdx[c] = i
	}

	// bucket key → delay values
	type bucketKey struct{ bin, dayType string }
	buckets := make(map[bucketKey][]float64)
	var allDelays []float64

	for rows.Next() {
		vals := rows.Values()
		delayStr := colVal(vals, colIdx, "delay_seconds")
		recAtStr := colVal(vals, colIdx, "recorded_at")

		delay, err := strconv.Atoi(delayStr)
		if err != nil {
			continue
		}
		t, err := parsePGTimestamp(recAtStr)
		if err != nil {
			continue
		}

		bin := timeBin(t.Hour())
		dt := dayType(t.Weekday())
		key := bucketKey{bin, dt}
		buckets[key] = append(buckets[key], float64(delay))
		allDelays = append(allDelays, float64(delay))
	}

	// Build sorted output (deterministic order).
	binOrder := []string{"morning", "midday", "afternoon", "evening", "night"}
	dayOrder := []string{"weekday", "weekend"}

	var byBin []TimeBinStats
	for _, bin := range binOrder {
		for _, dt := range dayOrder {
			key := bucketKey{bin, dt}
			vals, ok := buckets[key]
			if !ok {
				continue
			}
			byBin = append(byBin, TimeBinStats{
				TimeBin:         bin,
				DayType:         dt,
				SampleCount:     len(vals),
				AvgDelaySeconds: roundF(mean(vals)),
				P90DelaySeconds: roundF(percentile(vals, 90)),
			})
		}
	}

	result := ArrivalStats{
		RouteID:            routeID,
		StopID:             stopID,
		TotalSamples:       len(allDelays),
		ByTimeBin:          byBin,
	}
	if len(allDelays) > 0 {
		result.OverallAvgDelaySeconds = roundF(mean(allDelays))
	}
	return result, nil
}

// -------------------------------------------------------------------------
// helpers

func colVal(vals []string, idx map[string]int, col string) string {
	i, ok := idx[col]
	if !ok || i >= len(vals) {
		return ""
	}
	return vals[i]
}

// parsePGTimestamp handles "2006-01-02 15:04:05" and "2006-01-02 15:04:05.999999".
func parsePGTimestamp(s string) (time.Time, error) {
	s = strings.TrimSpace(s)
	for _, layout := range []string{
		"2006-01-02 15:04:05.999999",
		"2006-01-02 15:04:05",
		"2006-01-02T15:04:05Z",
	} {
		t, err := time.Parse(layout, s)
		if err == nil {
			return t.UTC(), nil
		}
	}
	return time.Time{}, fmt.Errorf("cannot parse timestamp %q", s)
}

func timeBin(hour int) string {
	switch {
	case hour >= 6 && hour < 9:
		return "morning"
	case hour >= 9 && hour < 15:
		return "midday"
	case hour >= 15 && hour < 18:
		return "afternoon"
	case hour >= 18 && hour < 21:
		return "evening"
	default:
		return "night"
	}
}

func dayType(wd time.Weekday) string {
	if wd == time.Saturday || wd == time.Sunday {
		return "weekend"
	}
	return "weekday"
}

func mean(vals []float64) float64 {
	if len(vals) == 0 {
		return 0
	}
	var sum float64
	for _, v := range vals {
		sum += v
	}
	return sum / float64(len(vals))
}

func percentile(vals []float64, p float64) float64 {
	if len(vals) == 0 {
		return 0
	}
	sorted := make([]float64, len(vals))
	copy(sorted, vals)
	sort.Float64s(sorted)
	idx := int(math.Ceil(p/100.0*float64(len(sorted)))) - 1
	if idx < 0 {
		idx = 0
	}
	if idx >= len(sorted) {
		idx = len(sorted) - 1
	}
	return sorted[idx]
}

func roundF(v float64) float64 {
	return math.Round(v*100) / 100
}
