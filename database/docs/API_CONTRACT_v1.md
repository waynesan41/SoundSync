# SoundSync API Contract (v1)

All endpoints are prefixed with `/v1`.

---

## 1. Standard Response Format

Success:

{
  "success": true,
  "data": {},
  "error": null
}

Error:

{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "message"
  }
}

---

## 2. Date Format

All timestamps returned by the API are ISO 8601 UTC strings.

Example:
"2026-02-17T03:21:45.123Z"

---

## 3. Coordinate Format

All coordinates use:

{ "lat": number, "lng": number }

---

## 4. GET /v1/routes

Returns a list of routes.

Response:

{
  "success": true,
  "data": {
    "routes": [
      {
        "id": "102592",
        "shortName": "E",
        "longName": "RapidRide E Line",
        "description": "Aurora Village → Downtown Seattle",
        "color": "#0057B8",
        "agencyName": "King County Metro"
      }
    ]
  },
  "error": null
}

---

## 5. GET /v1/routes/:id

Returns a single route including stops and polyline.

Response:

{
  "success": true,
  "data": {
    "route": {
      "id": "102592",
      "shortName": "E",
      "longName": "RapidRide E Line",
      "description": "Aurora Village → Downtown Seattle",
      "color": "#0057B8",
      "agencyName": "King County Metro",
      "polyline": "encoded_polyline_string",
      "stops": [
        {
          "id": "59540",
          "name": "3rd Ave & Pike St",
          "location": { "lat": 47.6101, "lng": -122.3366 }
        }
      ]
    }
  },
  "error": null
}

---

## 6. Error Example

{
  "success": false,
  "data": null,
  "error": {
    "code": "ROUTE_NOT_FOUND",
    "message": "Route not found"
  }
}
