"""Seed catalog for East & Central African launch markets."""
from __future__ import annotations

COUNTRIES = [
    {
        "code": "TZ",
        "name": "Tanzania",
        "official_name": "United Republic of Tanzania",
        "status": "active",
        "default_currency": "TZS",
        "supported_currencies": ["TZS", "USD", "EUR"],
        "languages": ["sw", "en"],
        "default_locale": "sw-TZ",
        "timezone": "Africa/Dar_es_Salaam",
        "data_region": "eastafrica-tz",
        "calling_code": "+255",
        "branding": {"primary": "#0B6E4F", "market_name": "Taifa Tanzania"},
    },
    {
        "code": "KE",
        "name": "Kenya",
        "official_name": "Republic of Kenya",
        "status": "pilot",
        "default_currency": "KES",
        "supported_currencies": ["KES", "USD"],
        "languages": ["en", "sw"],
        "default_locale": "en-KE",
        "timezone": "Africa/Nairobi",
        "data_region": "eastafrica-ke",
        "calling_code": "+254",
        "branding": {"primary": "#BB0000", "market_name": "Taifa Kenya"},
    },
    {
        "code": "UG",
        "name": "Uganda",
        "official_name": "Republic of Uganda",
        "status": "pilot",
        "default_currency": "UGX",
        "supported_currencies": ["UGX", "USD"],
        "languages": ["en"],
        "default_locale": "en-UG",
        "timezone": "Africa/Kampala",
        "data_region": "eastafrica-ug",
        "calling_code": "+256",
        "branding": {"primary": "#FCDC04", "market_name": "Taifa Uganda"},
    },
    {
        "code": "RW",
        "name": "Rwanda",
        "official_name": "Republic of Rwanda",
        "status": "planned",
        "default_currency": "RWF",
        "supported_currencies": ["RWF", "USD"],
        "languages": ["en", "fr", "sw"],
        "default_locale": "en-RW",
        "timezone": "Africa/Kigali",
        "data_region": "eastafrica-rw",
        "calling_code": "+250",
        "branding": {"primary": "#00A1DE", "market_name": "Taifa Rwanda"},
    },
    {
        "code": "BI",
        "name": "Burundi",
        "official_name": "Republic of Burundi",
        "status": "planned",
        "default_currency": "BIF",
        "supported_currencies": ["BIF", "USD"],
        "languages": ["fr", "en"],
        "default_locale": "fr-BI",
        "timezone": "Africa/Bujumbura",
        "data_region": "eastafrica-bi",
        "calling_code": "+257",
        "branding": {"primary": "#18B70B", "market_name": "Taifa Burundi"},
    },
    {
        "code": "ZM",
        "name": "Zambia",
        "official_name": "Republic of Zambia",
        "status": "planned",
        "default_currency": "ZMW",
        "supported_currencies": ["ZMW", "USD"],
        "languages": ["en"],
        "default_locale": "en-ZM",
        "timezone": "Africa/Lusaka",
        "data_region": "southernafrica-zm",
        "calling_code": "+260",
        "branding": {"primary": "#198A00", "market_name": "Taifa Zambia"},
    },
    {
        "code": "MW",
        "name": "Malawi",
        "official_name": "Republic of Malawi",
        "status": "planned",
        "default_currency": "MWK",
        "supported_currencies": ["MWK", "USD"],
        "languages": ["en"],
        "default_locale": "en-MW",
        "timezone": "Africa/Blantyre",
        "data_region": "southernafrica-mw",
        "calling_code": "+265",
        "branding": {"primary": "#CE1126", "market_name": "Taifa Malawi"},
    },
    {
        "code": "CD",
        "name": "DR Congo",
        "official_name": "Democratic Republic of the Congo",
        "status": "planned",
        "default_currency": "CDF",
        "supported_currencies": ["CDF", "USD"],
        "languages": ["fr"],
        "default_locale": "fr-CD",
        "timezone": "Africa/Kinshasa",
        "data_region": "centralafrica-cd",
        "calling_code": "+243",
        "branding": {"primary": "#007FFF", "market_name": "Taifa RDC"},
    },
]

FX_VS_USD = {
    "TZS": 265_000_000_000,  # ~2650
    "KES": 129_000_000_000,  # ~1290
    "UGX": 370_000_000_000,  # ~3700
    "RWF": 1_300_000_000_000,  # ~13000
    "BIF": 2_860_000_000_000,
    "ZMW": 2_700_000_000,  # ~27
    "MWK": 1_730_000_000_000,
    "CDF": 2_850_000_000_000,
    "EUR": 92_000_000,  # ~0.92
    "USD": 100_000_000,
}

LANGUAGE_PACKS = [
    {
        "locale": "en",
        "name": "English",
        "rtl": False,
        "strings": {
            "app.name": "Taifa",
            "wallet.title": "Wallet",
            "mobility.title": "Mobility",
            "gov.title": "Government",
            "ai.greeting": "Welcome to Taifa",
        },
    },
    {
        "locale": "sw",
        "name": "Kiswahili",
        "rtl": False,
        "strings": {
            "app.name": "Taifa",
            "wallet.title": "Pochi",
            "mobility.title": "Usafiri",
            "gov.title": "Serikali",
            "ai.greeting": "Karibu Taifa",
        },
    },
    {
        "locale": "fr",
        "name": "Français",
        "rtl": False,
        "strings": {
            "app.name": "Taifa",
            "wallet.title": "Portefeuille",
            "mobility.title": "Mobilité",
            "gov.title": "Gouvernement",
            "ai.greeting": "Bienvenue sur Taifa",
        },
    },
    {
        "locale": "ar",
        "name": "العربية",
        "rtl": True,
        "strings": {
            "app.name": "Taifa",
            "wallet.title": "المحفظة",
            "mobility.title": "التنقل",
            "gov.title": "الحكومة",
            "ai.greeting": "مرحبًا بكم في طائفة",
        },
    },
    {
        "locale": "pt",
        "name": "Português",
        "rtl": False,
        "strings": {
            "app.name": "Taifa",
            "wallet.title": "Carteira",
            "mobility.title": "Mobilidade",
            "gov.title": "Governo",
            "ai.greeting": "Bem-vindo à Taifa",
        },
    },
]

COMPLIANCE_TEMPLATES = [
    {
        "code": "aml-baseline",
        "name": "AML monitoring baseline",
        "category": "aml",
        "rules": {
            "daily_cash_threshold_minor": 1_000_000_00,
            "suspicious_velocity_txns": 20,
            "report_within_hours": 24,
        },
    },
    {
        "code": "kyc-baseline",
        "name": "KYC / CDD baseline",
        "category": "kyc",
        "rules": {
            "required_levels": ["basic", "verified"],
            "document_types": ["national_id", "passport"],
            "refresh_days": 365,
        },
    },
    {
        "code": "tax-reporting",
        "name": "Tax reporting hooks",
        "category": "tax",
        "rules": {"vat_enabled": True, "withholding_enabled": False},
    },
    {
        "code": "central-bank-reporting",
        "name": "Central bank transaction reporting",
        "category": "central_bank",
        "rules": {"batch_schedule": "daily", "format": "iso20022-compatible"},
    },
    {
        "code": "privacy-residency",
        "name": "Privacy and data residency",
        "category": "privacy",
        "rules": {"consent_required": True, "cross_border_default": False},
    },
    {
        "code": "audit-retention",
        "name": "Audit retention",
        "category": "audit",
        "rules": {"retention_days": 2555, "immutable_ledger": True},
    },
]

PAYMENT_RAILS = {
    "TZ": [
        ("tigopesa", "Tigo Pesa", ["TZS"]),
        ("mpesa", "M-Pesa", ["TZS"]),
        ("airtel", "Airtel Money", ["TZS"]),
        ("card", "Card", ["TZS", "USD"]),
    ],
    "KE": [
        ("mpesa", "M-Pesa", ["KES"]),
        ("card", "Card", ["KES", "USD"]),
        ("bank", "Bank Transfer", ["KES"]),
    ],
    "UG": [
        ("mtn", "MTN MoMo", ["UGX"]),
        ("airtel", "Airtel Money", ["UGX"]),
        ("card", "Card", ["UGX", "USD"]),
    ],
    "RW": [("momo", "MTN MoMo", ["RWF"]), ("card", "Card", ["RWF", "USD"])],
    "BI": [("lumicash", "Lumicash", ["BIF"]), ("card", "Card", ["BIF", "USD"])],
    "ZM": [("mtn", "MTN MoMo", ["ZMW"]), ("airtel", "Airtel Money", ["ZMW"]), ("card", "Card", ["ZMW", "USD"])],
    "MW": [("airtel", "Airtel Money", ["MWK"]), ("tnm", "TNM Mpamba", ["MWK"])],
    "CD": [("orange", "Orange Money", ["CDF"]), ("airtel", "Airtel Money", ["CDF", "USD"]), ("card", "Card", ["USD"])],
}

IDENTITY_PROVIDERS = {
    "TZ": [
        ("nida", "national_id", "NIDA"),
        ("brela", "business", "BRELA"),
        ("tra", "tax", "TRA"),
    ],
    "KE": [
        ("huduma", "national_id", "Huduma Namba / IPRS"),
        ("kra", "tax", "KRA"),
        ("brs", "business", "Business Registry"),
    ],
    "UG": [("nin", "national_id", "NIN"), ("ura", "tax", "URA")],
    "RW": [("nida", "national_id", "NIDA Rwanda"), ("rra", "tax", "RRA")],
    "BI": [("oni", "national_id", "ONI"), ("obr", "tax", "OBR")],
    "ZM": [("nrc", "national_id", "NRC"), ("zra", "tax", "ZRA")],
    "MW": [("national_id", "national_id", "National ID"), ("mra", "tax", "MRA")],
    "CD": [("cni", "national_id", "CNI"), ("dgda", "tax", "DGDA")],
}

CORRIDORS = [
    ("tz-ke-wallet", "TZ→KE Wallet", "TZ", "KE", "wallet", "TZS", "KES", "USD", 75),
    ("ke-tz-wallet", "KE→TZ Wallet", "KE", "TZ", "wallet", "KES", "TZS", "USD", 75),
    ("tz-ug-wallet", "TZ→UG Wallet", "TZ", "UG", "wallet", "TZS", "UGX", "USD", 80),
    ("tz-rw-wallet", "TZ→RW Wallet", "TZ", "RW", "wallet", "TZS", "RWF", "USD", 80),
    ("ke-ug-wallet", "KE→UG Wallet", "KE", "UG", "wallet", "KES", "UGX", "USD", 70),
    ("tz-zm-freight", "TZ→ZM Freight", "TZ", "ZM", "freight", "TZS", "ZMW", "USD", 100),
    ("tz-cd-logistics", "TZ→CD Logistics", "TZ", "CD", "logistics", "TZS", "CDF", "USD", 120),
    ("regional-merchant-usd", "Regional Merchant USD", "TZ", "KE", "merchant", "USD", "USD", "USD", 40),
]

PARTNERS = [
    {
        "partner_code": "demo-bank-ea",
        "legal_name": "East Africa Demo Bank",
        "partner_type": "bank",
        "countries": ["TZ", "KE", "UG"],
        "domains": ["enterprise", "commerce"],
        "status": "certified",
        "certification_tier": "gold",
    },
    {
        "partner_code": "demo-fintech-hub",
        "legal_name": "Fintech Hub Africa",
        "partner_type": "fintech",
        "countries": ["TZ", "KE", "RW"],
        "domains": ["commerce", "mobility"],
        "status": "certified",
        "certification_tier": "sandbox",
    },
    {
        "partner_code": "demo-uni-dsm",
        "legal_name": "University of Dar es Salaam Lab",
        "partner_type": "university",
        "countries": ["TZ"],
        "domains": ["education", "enterprise"],
        "status": "pending",
        "certification_tier": "sandbox",
    },
]
