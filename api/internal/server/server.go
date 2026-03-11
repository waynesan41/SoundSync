package server

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"time"

	"soundsync/api/internal/config"
	"soundsync/api/internal/router"

	_ "github.com/lib/pq"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func New(cfg *config.Config) *http.Server {
	mongoDB := connectMongo(cfg)
	pgDB := connectPostgres(cfg)

	r := router.New(cfg, mongoDB, pgDB)

	return &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
}

func connectMongo(cfg *config.Config) *mongo.Database {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOpts := options.Client().ApplyURI(cfg.MongoURI)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		log.Fatalf("MongoDB connect error: %v", err)
	}

	if err := client.Ping(ctx, nil); err != nil {
		log.Fatalf("MongoDB ping error: %v", err)
	}

	log.Printf("Connected to MongoDB: %s", cfg.MongoDB)
	return client.Database(cfg.MongoDB)
}

func connectPostgres(cfg *config.Config) *sql.DB {
	dsn := fmt.Sprintf(
		"host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
		cfg.PGHost, cfg.PGPort, cfg.PGDBName, cfg.PGUser, cfg.PGPassword,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("PostgreSQL open error: %v", err)
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		// Non-fatal: poller may not be running locally; log a warning and continue
		log.Printf("WARNING: PostgreSQL ping failed (%v) — reliability endpoints will return empty data", err)
	} else {
		log.Printf("Connected to PostgreSQL: %s/%s", cfg.PGHost, cfg.PGDBName)
	}

	return db
}
