package router

import (
	"database/sql"
	"net/http"

	"soundsync/api/internal/config"
	"soundsync/api/internal/handlers"
	"soundsync/api/internal/middleware"
	"soundsync/api/internal/repository"
	"soundsync/api/internal/services"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"go.mongodb.org/mongo-driver/mongo"
)

func New(cfg *config.Config, db *mongo.Database, pgDB *sql.DB) http.Handler {
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.RequestID)
	r.Use(chimiddleware.RealIP)
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://localhost:4173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: true,
	}))

	// Repos & services
	userRepo := repository.NewUserRepo(db)
	favRepo := repository.NewFavoriteRepo(db)
	reportRepo := repository.NewReportRepo(db)
	vehicleReportRepo := repository.NewVehicleReportRepo(db)
	notifRepo := repository.NewNotificationRepo(db)

	authSvc := services.NewAuthService(userRepo, cfg.JWTSecret)
	transitSvc := services.NewTransitService(cfg)
	routeSvc := services.NewRouteService(cfg)
	weatherSvc := services.NewWeatherService(cfg)
	reliabilitySvc := services.NewReliabilityService(pgDB)

	// Handlers
	authH := handlers.NewAuthHandler(authSvc)
	transitH := handlers.NewTransitHandler(transitSvc)
	routeH := handlers.NewRouteHandler(routeSvc, favRepo)
	weatherH := handlers.NewWeatherHandler(weatherSvc)
	userH := handlers.NewUserHandler(userRepo, favRepo, reportRepo, notifRepo)
	notifH := handlers.NewNotificationHandler(notifRepo)
	vehicleReportH := handlers.NewVehicleReportHandler(vehicleReportRepo)
	reliabilityH := handlers.NewReliabilityHandler(reliabilitySvc)

	// JWT middleware factory
	jwtAuth := middleware.NewJWTAuth(cfg.JWTSecret)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`{"status":"ok"}`))
	})

	r.Route("/api/v1", func(r chi.Router) {
		// Auth
		r.Post("/auth/register", authH.Register)
		r.Post("/auth/login", authH.Login)

		// Transit (public)
		r.Get("/transit/vehicles", transitH.GetVehicles)
		r.Get("/transit/stops", transitH.GetNearbyStops)
		r.Get("/transit/arrivals", transitH.GetArrivals)

		// Routes (public)
		r.Get("/routes/plan", routeH.PlanRoute)
		r.Get("/routes/{routeId}", routeH.GetRoute)

		// Weather (public)
		r.Get("/weather", weatherH.GetWeather)
		r.Get("/weather/hourly", weatherH.GetHourlyForecast)

		// Reliability & prediction (public) — register /summary before /{stopId}
		r.Get("/reliability/summary", reliabilityH.GetSummary)
		r.Get("/reliability/{stopId}", reliabilityH.GetStopReliability)
		r.Get("/reliability/{stopId}/{routeId}", reliabilityH.GetRouteStopReliability)
		r.Get("/prediction/{stopId}/{routeId}", reliabilityH.GetPrediction)

		// Vehicle reports (auth-guarded)
		r.Group(func(r chi.Router) {
			r.Use(jwtAuth)
			r.Post("/transit/vehicles/{vehicleId}/report/cleanliness", vehicleReportH.CreateCleanliness)
			r.Post("/transit/vehicles/{vehicleId}/report/crowding", vehicleReportH.CreateCrowding)
			r.Post("/transit/vehicles/{vehicleId}/report/delay", vehicleReportH.CreateDelay)
			r.Get("/users/me/vehicle-reports", vehicleReportH.GetMyReports)
			r.Delete("/users/me/vehicle-reports/{type}/{id}", vehicleReportH.DeleteMyReport)
		})

		// Authenticated
		r.Group(func(r chi.Router) {
			r.Use(jwtAuth)

			r.Get("/users/me", userH.GetMe)
			r.Patch("/users/me/settings", userH.UpdateSettings)
			r.Delete("/users/me", userH.DeleteMe)
			r.Get("/users/me/favorites", userH.GetFavorites)
			r.Post("/users/me/favorites", userH.CreateFavorite)
			r.Delete("/users/me/favorites/{id}", userH.DeleteFavorite)

			// Notifications — register read-all BEFORE {id}/read
			r.Get("/users/me/notifications", notifH.GetNotifications)
			r.Patch("/users/me/notifications/read-all", notifH.MarkAllRead)
			r.Patch("/users/me/notifications/{id}/read", notifH.MarkRead)

			r.Post("/reports", userH.CreateReport)
			r.Get("/reports", userH.GetReports)
		})
	})

	return r
}
