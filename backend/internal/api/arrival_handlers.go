package api

import (
	"net/http"
	"strconv"
	"strings"

	"soundsync/backend/internal/arrivals"
)

func (h *Handler) listArrivals(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	q := r.URL.Query()
	routeID := q.Get("routeId")
	stopID := q.Get("stopId")

	limit := 50
	if s := strings.TrimSpace(q.Get("limit")); s != "" {
		v, err := strconv.Atoi(s)
		if err != nil {
			writeError(w, http.StatusBadRequest, "limit must be an integer")
			return
		}
		limit = v
	}

	list, err := h.arrivalsSvc.List(routeID, stopID, limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to query arrivals: "+err.Error())
		return
	}

	// Return an empty array rather than null when there are no results.
	if list == nil {
		list = []arrivals.Arrival{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"arrivals": list})
}

func (h *Handler) arrivalStats(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.authorize(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	q := r.URL.Query()
	routeID := strings.TrimSpace(q.Get("routeId"))
	if routeID == "" {
		writeError(w, http.StatusBadRequest, "routeId is required")
		return
	}
	stopID := q.Get("stopId")

	stats, err := h.arrivalsSvc.Stats(routeID, stopID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to compute arrival stats: "+err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"stats": stats})
}
