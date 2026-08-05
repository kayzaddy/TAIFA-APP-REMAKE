# 3. Wallet Routing Guide

`WalletFundingPreference` stores ordered sources:

1. Taifa Wallet  
2. M-Pesa · Airtel · …  
3. Banks · Cards · Employer / Gift / Government / CBDC (extensible)

`resolve_funding` picks the first eligible source.  
**Capture today** requires wallet balance. Other sources return as fallbacks → top-up / future rail — **never duplicate charges**.
