# 4. Authentication Guide

Policies: `always` · `risk_based` · `low_friction` · `pin_only` · `biometric_preferred`

Low-risk threshold (default 50,000 minor) can skip step-up when policy allows.

Flutter simulates biometric / PIN before `POST .../tap/{code}/auth`.  
Real `local_auth` plugs into the same confirm gate.
