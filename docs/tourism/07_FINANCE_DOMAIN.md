# 07 — Finance Domain

**Bounded context:** `tourism.finance` (travel slice of Taifa Pay)  
**Strategic classification:** Generic — **ledger truth in Taifa Pay only**.

---

## 1. Business purpose

Travel payments: wallet, FX display, refunds, splits, loyalty, expenses, invoices—without duplicating ledger.

## 2. Responsibilities

Checkout capture orchestration handoff, travel wallet **read model**, split metadata, refund sagas, expense export—not booking prices.

## 3. Submodules

`checkout-capture` · `travel-wallet` · `fx` · `refunds` · `splits` · `loyalty` · `expenses` · `invoices`

## 4. Microservices

`payments` (platform) · `tourism-finance-facade` (metadata only)

## 5–7. Domain model

**Entities:** `PaymentIntent`, `SettlementPlan`, `TravelExpenseView`  
**Aggregates:** `CheckoutPayment` (idempotent capture)  
**Value objects:** `Money`, `IdempotencyKey`, `MerchantRef`, `SplitLine`

## 8. Domain events

`finance.payment.captured` · `finance.refund.completed` · `finance.split.scheduled`

## 9. APIs

Commerce `/pay` endpoints · enterprise `capture_merchant_payment` · future `tourism/finance/expenses`

## 10. Database tables

Ledger in `payments`/`enterprise`; tourism stores `payment_ref` on checkout/bookings only.

## 11. Event flows

Orchestration saga calls Finance once per checkout; Booking marks paid on `finance.payment.captured`.

## 12–15.

PCI tokenization; Aurora ledger; Fraud Detection; East Africa multi-currency.

**Anti-pattern:** Tourism tables storing authoritative balances.
