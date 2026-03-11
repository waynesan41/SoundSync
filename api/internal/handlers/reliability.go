package handlers

import (
	"net/http"

	"soundsync/api/internal/services"

	"github.com/go-chi/chi/v5"
)

type ReliabilityHandler struct {
	svc *services.ReliabilityService
}

func NewReliabilityHandler(svc *services.ReliabilityService) *ReliabilityHandler {
	return &ReliabilityHandler{svc: svc}
}

// GET /api/v1/reliability/summary
// Returns all tracked routes ranked by reliability score.
func (h *ReliabilityHandler) GetSummary(w http.ResponseWriter, r *http.Request) {
	entries, err := h.svc.GetSummary(r.Context())
	if err != nil {
		jsonOK(w, map[string]interface{}{"success": false, "error": "failed to compute reliability summary"}, http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{
		"success": true,
		"data":    map[string]interface{}{"routes": entries},
	}, http.StatusOK)
}

// GET /api/v1/reliability/{stopId}
// Returns reliability scores for all routes observed at the given stop.
func (h *ReliabilityHandler) GetStopReliability(w http.ResponseWriter, r *http.Request) {
	stopID := chi.URLParam(r, "stopId")
	if stopID == "" {
		jsonOK(w, map[string]interface{}{"success": false, "error": "stopId is required"}, http.StatusBadRequest)
		return
	}

	result, err := h.svc.GetStopReliability(r.Context(), stopID)
	if err != nil {
		jsonOK(w, map[string]interface{}{"success": false, "error": "failed to compute stop reliability"}, http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{
		"success": true,
		"data":    result,
	}, http.StatusOK)
}

// GET /api/v1/reliability/{stopId}/{routeId}
// Returns detailed reliability metrics for a specific route at a specific stop.
func (h *ReliabilityHandler) GetRouteStopReliability(w http.ResponseWriter, r *http.Request) {
	stopID := chi.URLParam(r, "stopId")
	routeID := chi.URLParam(r, "routeId")
	if stopID == "" || routeID == "" {
		jsonOK(w, map[string]interface{}{"success": false, "error": "stopId and routeId are required"}, http.StatusBadRequest)
		return
	}

	result, err := h.svc.GetRouteStopReliability(r.Context(), stopID, routeID)
	if err != nil {
		jsonOK(w, map[string]interface{}{"success": false, "error": "failed to compute route reliability"}, http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{
		"success": true,
		"data":    result,
	}, http.StatusOK)
}

// GET /api/v1/prediction/{stopId}/{routeId}
// Returns a predicted delay for the next arrival based on current time-of-day historical averages.
func (h *ReliabilityHandler) GetPrediction(w http.ResponseWriter, r *http.Request) {
	stopID := chi.URLParam(r, "stopId")
	routeID := chi.URLParam(r, "routeId")
	if stopID == "" || routeID == "" {
		jsonOK(w, map[string]interface{}{"success": false, "error": "stopId and routeId are required"}, http.StatusBadRequest)
		return
	}

	result, err := h.svc.GetPrediction(r.Context(), stopID, routeID)
	if err != nil {
		jsonOK(w, map[string]interface{}{"success": false, "error": "failed to compute prediction"}, http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]interface{}{
		"success": true,
		"data":    result,
	}, http.StatusOK)
}
