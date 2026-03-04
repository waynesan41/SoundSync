package api

import (
	"net/http"

	"soundsync/backend/internal/arrivals"
	"soundsync/backend/internal/auth"
	"soundsync/backend/internal/notifications"
	"soundsync/backend/internal/predictions"
	"soundsync/backend/internal/reports"
)

type Handler struct {
	authSvc       *auth.Service
	notif         *notifications.Service
	delayRepo     *reports.DelayService
	crowdingRepo  *reports.CrowdingService
	cleanRepo     *reports.CleanlinessService
	predictionSvc *predictions.Service
	arrivalsSvc   *arrivals.Service
}

func NewHandler(
	authSvc *auth.Service,
	notifSvc *notifications.Service,
	delaySvc *reports.DelayService,
	crowdingSvc *reports.CrowdingService,
	cleanlinessSvc *reports.CleanlinessService,
	predictionSvc *predictions.Service,
	arrivalsSvc *arrivals.Service,
) *Handler {
	return &Handler{
		authSvc:       authSvc,
		notif:         notifSvc,
		delayRepo:     delaySvc,
		crowdingRepo:  crowdingSvc,
		cleanRepo:     cleanlinessSvc,
		predictionSvc: predictionSvc,
		arrivalsSvc:   arrivalsSvc,
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.health)

	mux.HandleFunc("POST /api/v1/auth/signup", h.signup)
	mux.HandleFunc("POST /api/v1/auth/login", h.login)
	mux.HandleFunc("POST /api/v1/auth/logout", h.logout)

	mux.HandleFunc("GET /api/v1/notifications", h.getNotificationPreferences)
	mux.HandleFunc("PUT /api/v1/notifications/preferences", h.updateNotificationPreferences)
	mux.HandleFunc("POST /api/v1/notifications/subscriptions", h.addSubscription)
	mux.HandleFunc("DELETE /api/v1/notifications/subscriptions/", h.removeSubscription)

	mux.HandleFunc("POST /api/v1/delay-reports", h.createDelayReport)
	mux.HandleFunc("GET /api/v1/delay-reports", h.listDelayReports)
	mux.HandleFunc("POST /api/v1/crowding-reports", h.createCrowdingReport)
	mux.HandleFunc("GET /api/v1/crowding-reports", h.listCrowdingReports)
	mux.HandleFunc("POST /api/v1/cleanliness-reports", h.createCleanlinessReport)
	mux.HandleFunc("GET /api/v1/cleanliness-reports", h.listCleanlinessReports)

	mux.HandleFunc("GET /api/v1/predictions/delay", h.predictDelay)
	mux.HandleFunc("GET /api/v1/predictions/crowding", h.predictCrowding)

	mux.HandleFunc("GET /api/v1/arrivals", h.listArrivals)
	mux.HandleFunc("GET /api/v1/arrivals/stats", h.arrivalStats)
}

func (h *Handler) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
