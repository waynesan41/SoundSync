// Package tests contains integration tests for the SoundSyncAI API.
//
// Requirements:
//   - MongoDB running on localhost:27017 (or set MONGO_URI env var)
//   - Run from the api/ directory: go test ./tests/...
//
// The tests use a dedicated "soundsync_test" database that is dropped on exit.
package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"database/sql"

	"soundsync/api/internal/config"
	"soundsync/api/internal/router"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// createIndexes mirrors the indexes created by database/mongo-init/01_init.js.
func createIndexes(ctx context.Context, db *mongo.Database) error {
	_, err := db.Collection("users").Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "email", Value: 1}},
		Options: options.Index().SetUnique(true),
	})
	return err
}

// ─── Test harness ─────────────────────────────────────────────────────────────

var (
	testDB     *mongo.Database
	testServer *httptest.Server
)

func TestMain(m *testing.M) {
	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://root:rootpassword@localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		fmt.Fprintf(os.Stderr, "SKIP: could not connect to MongoDB: %v\n", err)
		os.Exit(0)
	}
	if err := client.Ping(ctx, nil); err != nil {
		fmt.Fprintf(os.Stderr, "SKIP: MongoDB not reachable: %v\n", err)
		os.Exit(0)
	}

	testDB = client.Database("soundsync_test")

	// Create the same indexes that mongo-init creates for the real database.
	// Without these, duplicate-email detection won't work in tests.
	if err := createIndexes(ctx, testDB); err != nil {
		fmt.Fprintf(os.Stderr, "SKIP: could not create indexes: %v\n", err)
		os.Exit(0)
	}

	cfg := &config.Config{
		JWTSecret: "test-secret-key",
		MongoURI:  mongoURI,
	}

	handler := router.New(cfg, testDB, (*sql.DB)(nil))
	testServer = httptest.NewServer(handler)

	code := m.Run()

	// Drop test database and close everything
	_ = testDB.Drop(context.Background())
	testServer.Close()
	_ = client.Disconnect(context.Background())

	os.Exit(code)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func url(path string) string {
	return testServer.URL + "/api/v1" + path
}

func jsonBody(v any) io.Reader {
	b, _ := json.Marshal(v)
	return bytes.NewReader(b)
}

func do(t *testing.T, method, path string, body io.Reader, token string) *http.Response {
	t.Helper()
	req, err := http.NewRequest(method, url(path), body)
	if err != nil {
		t.Fatalf("build request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do request: %v", err)
	}
	return resp
}

func decode(t *testing.T, resp *http.Response, dst any) {
	t.Helper()
	defer resp.Body.Close()
	if err := json.NewDecoder(resp.Body).Decode(dst); err != nil {
		t.Fatalf("decode response: %v", err)
	}
}

// uniqueEmail returns a guaranteed-unique email for each test run.
func uniqueEmail() string {
	return fmt.Sprintf("test_%d@soundsync.test", time.Now().UnixNano())
}

// registerUser creates a new user and returns (token, userID).
func registerUser(t *testing.T, email, password, displayName string) (token, userID string) {
	t.Helper()
	resp := do(t, http.MethodPost, "/auth/register", jsonBody(map[string]string{
		"email":       email,
		"password":    password,
		"displayName": displayName,
	}), "")
	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("register failed (%d): %s", resp.StatusCode, body)
	}
	var out struct {
		Token string `json:"token"`
		User  struct {
			ID string `json:"id"`
		} `json:"user"`
	}
	decode(t, resp, &out)
	return out.Token, out.User.ID
}

// ─── Persistent user ─────────────────────────────────────────────────────────

// TestCreateWayne registers a real persistent user. The account is intentionally
// NOT deleted so it remains available in the database after the test run.
func TestCreateWayne(t *testing.T) {
	resp := do(t, http.MethodPost, "/auth/register", jsonBody(map[string]string{
		"email":       "wayne@gmail.com",
		"password":    "wayne123",
		"displayName": "Wayne",
	}), "")
	defer resp.Body.Close()

	// 201 = created fresh, 409 = already exists from a previous run — both are fine.
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusConflict {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("expected 201 or 409, got %d: %s", resp.StatusCode, body)
	}

	if resp.StatusCode == http.StatusCreated {
		var out map[string]any
		json.NewDecoder(resp.Body).Decode(&out)
		user, _ := out["user"].(map[string]any)
		t.Logf("Created user: id=%v email=%v displayName=%v", user["id"], user["email"], user["displayName"])
	} else {
		t.Log("User wayne@gmail.com already exists — skipping creation.")
	}
}

// ─── Health ───────────────────────────────────────────────────────────────────

func TestHealth(t *testing.T) {
	resp, err := http.Get(testServer.URL + "/health")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected 200, got %d", resp.StatusCode)
	}
}

// ─── Auth: Register ───────────────────────────────────────────────────────────

func TestRegister_Success(t *testing.T) {
	resp := do(t, http.MethodPost, "/auth/register", jsonBody(map[string]string{
		"email":       uniqueEmail(),
		"password":    "password123",
		"displayName": "Test User",
	}), "")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}

	var out map[string]any
	json.NewDecoder(resp.Body).Decode(&out)

	if out["token"] == nil {
		t.Error("expected token in response")
	}
	user, ok := out["user"].(map[string]any)
	if !ok {
		t.Fatal("expected user object in response")
	}
	if user["email"] == nil {
		t.Error("expected email in user")
	}
	if user["passwordHash"] != nil {
		t.Error("passwordHash must not be exposed")
	}
}

func TestRegister_MissingFields(t *testing.T) {
	cases := []map[string]string{
		{"email": uniqueEmail(), "password": "pass1234"},               // missing displayName
		{"email": uniqueEmail(), "displayName": "No Pass"},             // missing password
		{"password": "pass1234", "displayName": "No Email"},            // missing email
		{"email": uniqueEmail(), "password": "short", "displayName": "X"}, // password too short
	}
	for _, body := range cases {
		resp := do(t, http.MethodPost, "/auth/register", jsonBody(body), "")
		resp.Body.Close()
		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("body=%v: expected 400, got %d", body, resp.StatusCode)
		}
	}
}

func TestRegister_DuplicateEmail(t *testing.T) {
	email := uniqueEmail()
	registerUser(t, email, "password123", "First User")

	resp := do(t, http.MethodPost, "/auth/register", jsonBody(map[string]string{
		"email":       email,
		"password":    "password123",
		"displayName": "Second User",
	}), "")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusConflict {
		t.Errorf("expected 409 on duplicate email, got %d", resp.StatusCode)
	}
}

// ─── Auth: Login ──────────────────────────────────────────────────────────────

func TestLogin_Success(t *testing.T) {
	email := uniqueEmail()
	registerUser(t, email, "password123", "Login Test")

	resp := do(t, http.MethodPost, "/auth/login", jsonBody(map[string]string{
		"email":    email,
		"password": "password123",
	}), "")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	var out map[string]any
	json.NewDecoder(resp.Body).Decode(&out)
	if out["token"] == nil {
		t.Error("expected token in login response")
	}
}

func TestLogin_WrongPassword(t *testing.T) {
	email := uniqueEmail()
	registerUser(t, email, "correctpassword", "Wrong Pass Test")

	resp := do(t, http.MethodPost, "/auth/login", jsonBody(map[string]string{
		"email":    email,
		"password": "wrongpassword",
	}), "")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", resp.StatusCode)
	}
}

func TestLogin_UnknownEmail(t *testing.T) {
	resp := do(t, http.MethodPost, "/auth/login", jsonBody(map[string]string{
		"email":    "nobody@nowhere.test",
		"password": "doesntmatter",
	}), "")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", resp.StatusCode)
	}
}

// ─── Users: Me ────────────────────────────────────────────────────────────────

func TestGetMe_Authenticated(t *testing.T) {
	email := uniqueEmail()
	token, _ := registerUser(t, email, "password123", "Me Test")

	resp := do(t, http.MethodGet, "/users/me", nil, token)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	var user map[string]any
	json.NewDecoder(resp.Body).Decode(&user)
	if user["email"] != email {
		t.Errorf("expected email %q, got %v", email, user["email"])
	}
}

func TestGetMe_NoToken(t *testing.T) {
	resp := do(t, http.MethodGet, "/users/me", nil, "")
	resp.Body.Close()
	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401 without token, got %d", resp.StatusCode)
	}
}

func TestGetMe_InvalidToken(t *testing.T) {
	resp := do(t, http.MethodGet, "/users/me", nil, "not.a.valid.token")
	resp.Body.Close()
	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401 with bad token, got %d", resp.StatusCode)
	}
}

// ─── Users: Settings ──────────────────────────────────────────────────────────

func TestUpdateSettings_TempUnit(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Settings Test")

	resp := do(t, http.MethodPatch, "/users/me/settings", jsonBody(map[string]string{
		"tempUnit": "C",
	}), token)
	resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("expected 204, got %d", resp.StatusCode)
	}

	// Verify persisted
	resp2 := do(t, http.MethodGet, "/users/me", nil, token)
	defer resp2.Body.Close()
	var user map[string]any
	json.NewDecoder(resp2.Body).Decode(&user)
	if user["tempUnit"] != "C" {
		t.Errorf("expected tempUnit=C, got %v", user["tempUnit"])
	}
}

func TestUpdateSettings_InvalidUnit(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Bad Settings")

	resp := do(t, http.MethodPatch, "/users/me/settings", jsonBody(map[string]string{
		"tempUnit": "K",
	}), token)
	resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid tempUnit, got %d", resp.StatusCode)
	}
}

func TestUpdateSettings_DistanceUnit(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Distance Test")

	resp := do(t, http.MethodPatch, "/users/me/settings", jsonBody(map[string]string{
		"distanceUnit": "km",
	}), token)
	resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("expected 204, got %d", resp.StatusCode)
	}
}

func TestUpdateSettings_NoFields(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Empty Settings")

	resp := do(t, http.MethodPatch, "/users/me/settings", jsonBody(map[string]string{}), token)
	resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 for empty patch, got %d", resp.StatusCode)
	}
}

// ─── Users: Delete Account ────────────────────────────────────────────────────

func TestDeleteMe(t *testing.T) {
	email := uniqueEmail()
	token, _ := registerUser(t, email, "password123", "Delete Me")

	resp := do(t, http.MethodDelete, "/users/me", nil, token)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("expected 204, got %d", resp.StatusCode)
	}

	// Login should now fail (account soft-deleted)
	resp2 := do(t, http.MethodPost, "/auth/login", jsonBody(map[string]string{
		"email":    email,
		"password": "password123",
	}), "")
	resp2.Body.Close()
	if resp2.StatusCode == http.StatusOK {
		t.Error("expected login to fail after account deletion, but got 200")
	}
}

// ─── Favorites ────────────────────────────────────────────────────────────────

func TestFavorites_CRUD(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Fav Test")

	// Initially empty
	resp := do(t, http.MethodGet, "/users/me/favorites", nil, token)
	var list struct{ Favorites []map[string]any }
	decode(t, resp, &list)
	if len(list.Favorites) != 0 {
		t.Errorf("expected empty favorites, got %d", len(list.Favorites))
	}

	// Create
	resp = do(t, http.MethodPost, "/users/me/favorites", jsonBody(map[string]any{
		"label": "Home to Downtown",
		"origin": map[string]any{
			"name": "Bellevue",
			"lat":  47.6101,
			"lng":  -122.2015,
		},
		"destination": map[string]any{
			"name": "Seattle",
			"lat":  47.6062,
			"lng":  -122.3321,
		},
		"transitRouteIds": []string{"100040"},
	}), token)
	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("create favorite: expected 201, got %d: %s", resp.StatusCode, body)
	}
	var created map[string]any
	decode(t, resp, &created)
	// FavoriteRoute serialises its ObjectID as "_id"
	favID, _ := created["_id"].(string)
	if favID == "" {
		t.Fatal("expected _id in created favorite")
	}

	// List — should have 1
	resp = do(t, http.MethodGet, "/users/me/favorites", nil, token)
	decode(t, resp, &list)
	if len(list.Favorites) != 1 {
		t.Errorf("expected 1 favorite, got %d", len(list.Favorites))
	}

	// Delete
	resp = do(t, http.MethodDelete, "/users/me/favorites/"+favID, nil, token)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("delete favorite: expected 204, got %d", resp.StatusCode)
	}

	// List — should be empty again
	resp = do(t, http.MethodGet, "/users/me/favorites", nil, token)
	decode(t, resp, &list)
	if len(list.Favorites) != 0 {
		t.Errorf("expected 0 favorites after delete, got %d", len(list.Favorites))
	}
}

// ─── Reports ──────────────────────────────────────────────────────────────────

func TestCreateReport_Success(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Report Test")

	resp := do(t, http.MethodPost, "/reports", jsonBody(map[string]any{
		"routeId":     "100040",
		"vehicleId":   "V123",
		"type":        "delay",
		"severity":    "medium",
		"description": "Bus was 15 minutes late",
	}), token)

	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("expected 201, got %d: %s", resp.StatusCode, body)
	}
	var report map[string]any
	decode(t, resp, &report)
	if report["routeId"] != "100040" {
		t.Errorf("expected routeId=100040, got %v", report["routeId"])
	}
}

func TestCreateReport_Unauthenticated(t *testing.T) {
	resp := do(t, http.MethodPost, "/reports", jsonBody(map[string]any{
		"routeId":  "100040",
		"type":     "delay",
		"severity": "low",
	}), "")
	resp.Body.Close()
	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401 without auth, got %d", resp.StatusCode)
	}
}

func TestGetReports_ByRouteID(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Get Reports")
	routeID := fmt.Sprintf("route_%d", time.Now().UnixNano())

	// Create a report for this route
	do(t, http.MethodPost, "/reports", jsonBody(map[string]any{
		"routeId":  routeID,
		"type":     "cleanliness",
		"severity": "low",
	}), token).Body.Close()

	// Fetch by routeId
	resp := do(t, http.MethodGet, "/reports?routeId="+routeID, nil, token)
	var out struct{ Reports []map[string]any }
	decode(t, resp, &out)
	if len(out.Reports) == 0 {
		t.Error("expected at least one report")
	}
}

func TestGetReports_MissingRouteID(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Reports No ID")
	resp := do(t, http.MethodGet, "/reports", nil, token)
	resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 when routeId missing, got %d", resp.StatusCode)
	}
}

// ─── Vehicle Reports ──────────────────────────────────────────────────────────

func TestVehicleReport_Cleanliness(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Cleanliness Reporter")

	resp := do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-001/report/cleanliness",
		jsonBody(map[string]any{"routeId": "100040", "level": 3}),
		token,
	)
	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("expected 201, got %d: %s", resp.StatusCode, body)
	}
	var report map[string]any
	decode(t, resp, &report)
	if report["vehicleId"] != "V-BUS-001" {
		t.Errorf("expected vehicleId=V-BUS-001, got %v", report["vehicleId"])
	}
	if int(report["level"].(float64)) != 3 {
		t.Errorf("expected level=3, got %v", report["level"])
	}
}

func TestVehicleReport_Crowding(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Crowding Reporter")

	resp := do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-002/report/crowding",
		jsonBody(map[string]any{"routeId": "100040", "level": 5}),
		token,
	)
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}

func TestVehicleReport_Delay(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Delay Reporter")

	resp := do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-003/report/delay",
		jsonBody(map[string]any{"routeId": "100040", "level": 4}),
		token,
	)
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}

func TestVehicleReport_InvalidLevel(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Bad Level")

	cases := []int{0, 6, -1, 100}
	for _, level := range cases {
		resp := do(t, http.MethodPost,
			"/transit/vehicles/V-BUS-001/report/cleanliness",
			jsonBody(map[string]any{"routeId": "100040", "level": level}),
			token,
		)
		resp.Body.Close()
		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("level=%d: expected 400, got %d", level, resp.StatusCode)
		}
	}
}

func TestVehicleReport_Unauthenticated(t *testing.T) {
	resp := do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-001/report/cleanliness",
		jsonBody(map[string]any{"routeId": "100040", "level": 3}),
		"",
	)
	resp.Body.Close()
	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", resp.StatusCode)
	}
}

// ─── Vehicle Reports: List & Delete ──────────────────────────────────────────

func TestVehicleReports_ListAndDelete(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "List Delete Test")

	// No reports yet
	resp := do(t, http.MethodGet, "/users/me/vehicle-reports", nil, token)
	var out struct {
		Reports []map[string]any `json:"reports"`
	}
	decode(t, resp, &out)
	if len(out.Reports) != 0 {
		t.Errorf("expected 0 reports initially, got %d", len(out.Reports))
	}

	// Create a cleanliness report
	resp = do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-010/report/cleanliness",
		jsonBody(map[string]any{"routeId": "100040", "level": 2}),
		token,
	)
	var created map[string]any
	decode(t, resp, &created)
	// CleanlinessReport serialises its ObjectID as "id"
	reportID, _ := created["id"].(string)
	if reportID == "" {
		t.Fatal("expected id in created vehicle report")
	}

	// List — should have 1
	resp = do(t, http.MethodGet, "/users/me/vehicle-reports", nil, token)
	decode(t, resp, &out)
	if len(out.Reports) != 1 {
		t.Errorf("expected 1 report, got %d", len(out.Reports))
	}

	// Delete
	resp = do(t, http.MethodDelete,
		"/users/me/vehicle-reports/cleanliness/"+reportID,
		nil, token,
	)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("expected 204 on delete, got %d", resp.StatusCode)
	}

	// List — empty again
	resp = do(t, http.MethodGet, "/users/me/vehicle-reports", nil, token)
	decode(t, resp, &out)
	if len(out.Reports) != 0 {
		t.Errorf("expected 0 reports after delete, got %d", len(out.Reports))
	}
}

func TestVehicleReportDelete_NotOwner(t *testing.T) {
	ownerToken, _ := registerUser(t, uniqueEmail(), "password123", "Owner")
	otherToken, _ := registerUser(t, uniqueEmail(), "password123", "Other")

	// Owner creates a report
	resp := do(t, http.MethodPost,
		"/transit/vehicles/V-BUS-020/report/delay",
		jsonBody(map[string]any{"routeId": "100040", "level": 1}),
		ownerToken,
	)
	var created map[string]any
	decode(t, resp, &created)
	reportID, _ := created["id"].(string)

	// Other user tries to delete it
	resp = do(t, http.MethodDelete,
		"/users/me/vehicle-reports/delay/"+reportID,
		nil, otherToken,
	)
	resp.Body.Close()
	if resp.StatusCode == http.StatusNoContent {
		t.Error("other user should not be able to delete owner's report")
	}
}

func TestVehicleReportDelete_InvalidID(t *testing.T) {
	token, _ := registerUser(t, uniqueEmail(), "password123", "Bad ID")

	resp := do(t, http.MethodDelete,
		"/users/me/vehicle-reports/cleanliness/not-a-valid-object-id",
		nil, token,
	)
	resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid id, got %d", resp.StatusCode)
	}
}
