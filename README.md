# Transit Reliability App

A next-generation transit app combining real-time data, historical reliability analysis, and AI-powered predictions to help riders make informed transit decisions.

## Overview

This app addresses public transit reliability challenges by:
- Providing real-time bus tracking with reliability scores
- Offering AI-enhanced arrival predictions using historical data
- Helping users plan routes based on actual transit performance
- Supporting city planners with data-driven insights for route improvements

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND LAYER                            │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │   React Native App   │      │   React Web App      │        │
│  │   (iOS + Android)    │      │                      │        │
│  └──────────────────────┘      └──────────────────────┘        │
│           │                              │                       │
│           └──────────────┬───────────────┘                      │
└────────────────────────────│────────────────────────────────────┘
                             │ HTTPS / WebSocket
┌────────────────────────────│────────────────────────────────────┐
│                        BACKEND LAYER                             │
│                             │                                    │
│  ┌──────────────────────────▼────────────────────────┐          │
│  │              API Gateway (Express.js)              │          │
│  └───────┬──────────────────┬───────────────┬────────┘          │
│          │                  │               │                    │
│  ┌───────▼────────┐  ┌──────▼──────┐  ┌────▼─────────┐         │
│  │ ML Prediction  │  │Data Collector│  │ Reliability  │         │
│  │    Engine      │  │   Service    │  │   Analyzer   │         │
│  └────────────────┘  └──────────────┘  └──────────────┘         │
│          │                  │               │                    │
│  ┌───────▼──────────────────▼───────────────▼────────┐          │
│  │         Cache (Redis) + Database (PostgreSQL)      │          │
│  └────────────────────────────────────────────────────┘          │
└────────────────────────────│────────────────────────────────────┘
                             │ API Calls
┌────────────────────────────│────────────────────────────────────┐
│                  EXTERNAL SERVICES LAYER                         │
│                             │                                    │
│  ┌──────────┐  ┌────────────▼──┐  ┌────────────┐  ┌─────────┐ │
│  │ Google   │  │  OneBusAway   │  │   Claude   │  │ Weather │ │
│  │ Maps API │  │      API      │  │  LLM API   │  │   API   │ │
│  └──────────┘  └───────────────┘  └────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

**Frontend:** React Native (Mobile), React.js (Web)  
**Backend:** Express.js, Python  
**Database:** PostgreSQL with PostGIS  
**Cache:** Redis  
**AI/ML:** Claude API (Anthropic), scikit-learn  
**Infrastructure:** Docker, AWS

## Key Features

- Real-time bus tracking with live arrival predictions
- Historical reliability scoring by route and time of day
- AI-enhanced predictions using LLM analysis
- Route planning with delay forecasting
- Interactive maps with bus locations

