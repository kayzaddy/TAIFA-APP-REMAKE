"""Knowledge platform — index documents and semantic retrieval with citations."""
from __future__ import annotations

import math
import re

from django.utils import timezone

from django.db.models import Q

from .adapters import _hash_embed
from .models import KnowledgeDocument, VectorDocument


def index_document(doc: KnowledgeDocument) -> VectorDocument:
    embedding = _hash_embed(f"{doc.title}\n{doc.body}", dims=32)
    VectorDocument.objects.filter(
        collection="knowledge", external_id=doc.code
    ).delete()
    vec = VectorDocument.objects.create(
        collection="knowledge",
        external_id=doc.code,
        text=f"{doc.title}\n{doc.body}",
        embedding=embedding,
        domain_code=doc.domain_code,
        metadata={
            "title": doc.title,
            "citation": doc.citation,
            "category": doc.category,
            "source_uri": doc.source_uri,
        },
    )
    doc.indexed_at = timezone.now()
    doc.save(update_fields=["indexed_at"])
    return vec


def index_all_active() -> int:
    count = 0
    for doc in KnowledgeDocument.objects.filter(active=True):
        index_document(doc)
        count += 1
    return count


def _cosine(a: list[float], b: list[float]) -> float:
    if not a or not b or len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


def semantic_search(
    *,
    query: str,
    domain_code: str = "",
    limit: int = 5,
) -> list[dict]:
    q_emb = _hash_embed(query, dims=32)
    qs = VectorDocument.objects.filter(collection="knowledge")
    if domain_code:
        qs = qs.filter(Q(domain_code__iexact=domain_code) | Q(domain_code=""))
    scored = []
    # Also boost lexical overlap for stub embeddings
    tokens = set(re.findall(r"[a-z0-9]+", query.lower()))
    for row in qs[:500]:
        score = _cosine(q_emb, list(row.embedding or []))
        text_l = row.text.lower()
        overlap = sum(1 for t in tokens if t in text_l)
        score += 0.05 * overlap
        scored.append((score, row))
    scored.sort(key=lambda x: x[0], reverse=True)
    results = []
    for score, row in scored[:limit]:
        meta = row.metadata or {}
        results.append(
            {
                "document_code": row.external_id,
                "title": meta.get("title") or row.external_id,
                "citation": meta.get("citation") or "",
                "category": meta.get("category") or "",
                "domain_code": row.domain_code,
                "snippet": row.text[:280],
                "score_e4": int(max(0, min(1, score)) * 10_000),
                "source_uri": meta.get("source_uri") or "",
            }
        )
    return results
