package app

import (
	"context"
	"net/http"
	"os"
	"time"

	"soundsync/backend/internal/api"
	"soundsync/backend/internal/arrivals"
	"soundsync/backend/internal/auth"
	"soundsync/backend/internal/db"
	"soundsync/backend/internal/notifications"
	"soundsync/backend/internal/predictions"
	"soundsync/backend/internal/reports"
)

type Runtime struct {
	Server   *http.Server
	Shutdown func(ctx context.Context) error
}

func New() (*Runtime, error) {
	addr := envOrDefault("APP_ADDR", ":8080")
	mongoURI := envOrDefault("MONGO_URI", "mongodb://admin:adminpassword@localhost:27017/?directConnection=true")
	dbName := envOrDefault("MONGO_DB", "soundsync")
	jwtSecret := envOrDefault("JWT_SECRET", "replace-this-secret")
	jwtTTL := durationOrDefault("JWT_TTL", 24*time.Hour)

	client, err := db.Connect(context.Background(), mongoURI)
	if err != nil {
		return nil, err
	}
	database := client.Database(dbName)

	authSvc, err := auth.NewService(database, jwtSecret, jwtTTL)
	if err != nil {
		_ = client.Disconnect(context.Background())
		return nil, err
	}
	notifSvc := notifications.NewService(database)
	delaySvc, err := reports.NewDelayService(database)
	if err != nil {
		_ = client.Disconnect(context.Background())
		return nil, err
	}
	crowdingSvc, err := reports.NewCrowdingService(database)
	if err != nil {
		_ = client.Disconnect(context.Background())
		return nil, err
	}
	cleanlinessSvc, err := reports.NewCleanlinessService(database)
	if err != nil {
		_ = client.Disconnect(context.Background())
		return nil, err
	}

	predictionSvc := predictions.NewService(database)

	pgCfg := db.PGConfig{
		Host:     envOrDefault("PG_HOST", "localhost"),
		Port:     envOrDefault("PG_PORT", "5432"),
		DBName:   envOrDefault("PG_DBNAME", "soundsync"),
		User:     envOrDefault("PG_USER", "postgres"),
		Password: envOrDefault("PG_PASSWORD", ""),
	}
	arrivalsSvc := arrivals.NewService(pgCfg)

	apiHandler := api.NewHandler(authSvc, notifSvc, delaySvc, crowdingSvc, cleanlinessSvc, predictionSvc, arrivalsSvc)

	mux := http.NewServeMux()
	apiHandler.Register(mux)

	server := &http.Server{
		Addr:    addr,
		Handler: mux,
	}

	shutdown := func(ctx context.Context) error {
		shutdownCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdownCtx)
		return client.Disconnect(shutdownCtx)
	}

	return &Runtime{Server: server, Shutdown: shutdown}, nil
}

func envOrDefault(key, fallback string) string {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	return v
}

func durationOrDefault(key string, fallback time.Duration) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return fallback
	}
	return d
}
