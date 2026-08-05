# 5. AI Assistant Guide

AI is a **personal assistant**, not a payment authority.

## Allowed

Find services · compare options · explain receipts · suggest routes · open modules via guidance

## Forbidden

Authorize payments · complete transfers · override user approval · invent balances

Enforced in `MockAiGateway` refusal phrases for authorize/pay-for-me intents.

Future live LLMs must keep the same hard guard (server-side AI OS already blocks `authorize_payment` capabilities).
