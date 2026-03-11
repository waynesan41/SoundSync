package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port           string
	Env            string
	MongoURI       string
	MongoDB        string
	JWTSecret      string
	GoogleMapsKey  string
	GTFSVehicleURL string
	GTFSTripURL    string
	GTFSAlertURL   string
	OBABaseURL     string
	OBAApiKey      string
	// PostgreSQL — transit poller arrivals database
	PGHost     string
	PGPort     string
	PGDBName   string
	PGUser     string
	PGPassword string
}

func Load() *Config {
	// Try the monorepo root (.env sits one level above api/)
	// then fall back to a local .env, then plain environment variables
	for _, path := range []string{"../.env", ".env"} {
		if err := godotenv.Load(path); err == nil {
			log.Printf("Loaded env from %s", path)
			break
		}
	}

	return &Config{
		Port:      getEnv("API_PORT", "8080"),
		Env:       getEnv("ENVIRONMENT", "development"),
		MongoURI:  getEnv("MONGO_URI", "mongodb://soundsync_app:apppassword@localhost:27017/soundsync"),
		MongoDB:   getEnv("MONGO_DB", "soundsync"),
		JWTSecret: getEnv("JWT_SECRET", "change_me_in_production"),
		GoogleMapsKey: getEnv("GOOGLE_MAPS_API_KEY", ""),
		GTFSVehicleURL: getEnv("GTFS_VEHICLE_POSITIONS_URL", ""), // deprecated KCM S3 feed; set to override
		GTFSTripURL: getEnv("GTFS_TRIP_UPDATES_URL",
			"https://s3.amazonaws.com/gtfs.soundtransit.org/TripUpdate_enhanced.pb"),
		GTFSAlertURL: getEnv("GTFS_SERVICE_ALERTS_URL",
			"https://s3.amazonaws.com/gtfs.soundtransit.org/ServiceAlert_enhanced.pb"),
		OBABaseURL: getEnv("OBA_BASE_URL", "https://api.pugetsound.onebusaway.org"),
		OBAApiKey:  getEnv("OBA_API_KEY", "TEST"),
		PGHost:     getEnv("PG_HOST", "localhost"),
		PGPort:     getEnv("PG_PORT", "5432"),
		PGDBName:   getEnv("PG_DBNAME", "soundsync"),
		PGUser:     getEnv("PG_USER", "postgres"),
		PGPassword: getEnv("PG_PASSWORD", ""),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
