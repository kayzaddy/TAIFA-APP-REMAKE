# Taifa Express — Merchant Guide

## What merchants get

A digital neighbourhood storefront: profile, inventory, hours, delivery radius, prep time, ratings.

Express ranks your shop when customers search nearby — customers do **not** browse shops first.

## Foundation profile fields

- Name, category, logo/banner URLs  
- Lat/lng + delivery radius  
- Prep minutes, rating, reliability, workload  
- Products: SKU, price, stock qty/status, tags  

Seed demo stores: `python manage.py seed_express`

## Incoming order flow

1. Customer checkout creates an `ExpressOrder` against the winning store.  
2. Auto-accept (foundation) or merchant `POST …/accept`.  
3. Payment settles via Taifa Commerce → Payments.  
4. Rider requested via Mobility.  
5. Merchant prepares items; mark ready when kitchen/counter is done (ops extension).

## Do / don't

| Do | Don't |
| --- | --- |
| Keep stock accurate | Duplicate POS settlement outside MAP/Payments |
| Keep prep times honest | Force customers to pick your shop first |
| Use Merchant Wallet for payouts | Invent a second ledger |
