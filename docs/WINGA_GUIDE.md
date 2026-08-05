# Winga Participant Guide

## For Wingas

1. Register profile: `POST /api/v1/winga/wingas`
2. Complete KYC → ops `POST /wingas/{id}/verify`
3. Create leads, attach quotations, open deals
4. Advance stages until `accepted`
5. Customer pays; after fulfillment, ops/system settles commission to your Taifa Wallet

## For Providers

1. `POST /api/v1/winga/providers` → KYB verify
2. Publish offerings (`POST /offerings`) with pricing, availability, booking attrs
3. Accept quotes / fulfill deals
4. Settlements to merchant payable via Taifa Payments (existing merchant settlement)

## For Customers

1. Browse `GET /offerings?domain=hotels&q=…`
2. Work with a Winga or open a deal
3. Pay only through `POST /deals/{id}/pay` (wallet / ledger)
4. Review Winga and provider after fulfillment

## Trust rules

- Unverified Wingas/Providers cannot collect payment
- Ratings update reputation scores (ops jobs can roll up later)
- Disputes freeze progression to `disputed`
