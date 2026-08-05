"""TAIFA Enterprise Financial Platform.

Attaches to the Payment Engine exclusively via:
  Orchestrator → journal recipes → ledger → domain events → projections.

Never posts money outside `payments.journal` / `payments.ledger`.
"""
