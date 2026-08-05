# Continental Compliance

## Configurable engine

`ComplianceProfile` rows are versioned JSON rules per country and category:

- aml · kyc · cdd · tax · central_bank · privacy · audit

Products call `POST /api/v1/continental/compliance/evaluate` — they do not hardcode thresholds.

## Identity federation

`IdentityFederationBinding` maps country + provider to an adapter class. Override live adapters with:

```bash
TAIFA_IDENTITY_ADAPTERS_JSON={"TZ.nida":"myapp.adapters.NidaLiveAdapter"}
```

Stub adapters are safe defaults for sandbox.

## Certification targets

ISO 27001 · SOC 2 · PCI DSS · ISO 22301 · ISO 20022-compatible reporting formats (configured per central-bank profile).
