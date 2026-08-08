"""Taifa Mobility BRT — Phase 1–2 HTTP API."""
from __future__ import annotations

from django.shortcuts import get_object_or_404
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from commerce.services import CommerceError
from payments.auth import IsDevice

from .national_models import PublicTransitRoute, TransitScheduledRun, TransitStationProfile, TransitTicketProduct, TransportTicket
from .permissions import IsMobilityOperator, IsTransitDriver, IsTransitValidator, owner_of
from .services import MobilityError
from . import transit_services as svc


def _float_param(value: str | None) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_home")
class TransitHomeView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        lat = _float_param(request.query_params.get("lat"))
        lng = _float_param(request.query_params.get("lng"))
        region = request.query_params.get("region") or "Dar es Salaam"
        mode = request.query_params.get("mode") or ""
        return Response(
            svc.transit_home_bundle(
                principal=owner_of(request),
                lat=lat,
                lng=lng,
                region=region,
                mode=mode,
            )
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_modes")
class TransitModesView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        region = request.query_params.get("region") or "Dar es Salaam"
        return Response(svc.transit_modes_catalog(region=region))


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_routes_list")
class TransitRouteListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            {
                "routes": svc.list_transit_routes(
                    region=request.query_params.get("region") or "",
                    mode=request.query_params.get("mode") or "",
                )
            }
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_routes_retrieve")
class TransitRouteDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, route_id):
        route = get_object_or_404(PublicTransitRoute, pk=route_id, active=True)
        return Response(svc.route_to_dict(route, include_departures=True))


@extend_schema(
    tags=["mobility-transit"],
    operation_id="mobility_transit_stations_nearby",
    parameters=[
        OpenApiParameter("lat", float, required=True),
        OpenApiParameter("lng", float, required=True),
        OpenApiParameter("limit", int, required=False),
    ],
)
class TransitNearbyStationsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        lat = _float_param(request.query_params.get("lat"))
        lng = _float_param(request.query_params.get("lng"))
        if lat is None or lng is None:
            return Response({"detail": "lat and lng required"}, status=400)
        limit = int(request.query_params.get("limit") or 8)
        return Response({"stations": svc.nearby_stations(lat=lat, lng=lng, limit=limit)})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_stations_retrieve")
class TransitStationDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, stop_code):
        try:
            return Response(svc.station_detail(stop_code=stop_code))
        except TransitStationProfile.DoesNotExist:
            return Response({"detail": "station not found"}, status=404)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_search")
class TransitSearchView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        query = request.query_params.get("q") or request.query_params.get("query") or ""
        return Response(
            svc.search_transit(
                query=query,
                region=request.query_params.get("region") or "",
            )
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_tickets_purchase")
class TransitTicketPurchaseView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        key = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        route_id = request.data.get("route_id")
        product_code = request.data.get("product_code") or "brt_single"
        if not route_id:
            return Response({"detail": "route_id required"}, status=400)
        try:
            ticket = svc.purchase_transit_ticket(
                owner=owner_of(request),
                actor=owner_of(request),
                route_id=route_id,
                product_code=product_code,
                origin_stop=str(request.data.get("origin_stop") or ""),
                destination_stop=str(request.data.get("destination_stop") or ""),
                idempotency_key=key,
                beneficiary_owner=str(request.data.get("beneficiary_owner") or ""),
            )
        except CommerceError as exc:
            return Response({"detail": str(exc)}, status=409)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.ticket_to_dict(ticket), status=201)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_tickets_mine")
class TransitMyTicketsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"tickets": svc.list_my_tickets(owner=owner_of(request))})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_tickets_validate")
class TransitTicketValidateView(APIView):
    permission_classes = [IsDevice, IsTransitValidator]

    def post(self, request):
        media_code = request.data.get("media_code") or request.data.get("qr_token")
        if not media_code:
            return Response({"detail": "media_code required"}, status=400)
        media_type = str(request.data.get("media_type") or "qr").lower()
        try:
            ticket = svc.validate_transit_ticket(
                media_code=str(media_code),
                actor=owner_of(request),
                qr_payload=request.data.get("qr") or request.data.get("qr_payload"),
                media_type=media_type,
            )
        except MobilityError as exc:
            return Response({"detail": str(exc), "valid": False}, status=400)
        except TransportTicket.DoesNotExist:
            return Response({"detail": "not found", "valid": False}, status=404)
        return Response({"valid": True, "ticket": svc.ticket_to_dict(ticket)})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_products_list")
class TransitProductListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            {
                "products": svc.list_transit_products(
                    mode=request.query_params.get("mode") or "",
                )
            }
        )


@extend_schema(
    tags=["mobility-transit"],
    operation_id="mobility_transit_plan",
    parameters=[
        OpenApiParameter("origin_stop", str, required=True),
        OpenApiParameter("destination_stop", str, required=True),
        OpenApiParameter("region", str, required=False),
    ],
)
class TransitPlanView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        origin = request.query_params.get("origin_stop") or ""
        destination = request.query_params.get("destination_stop") or ""
        try:
            return Response(
                svc.plan_transit_journey(
                    origin_stop=origin,
                    destination_stop=destination,
                    region=request.query_params.get("region") or "",
                )
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_driver_runs_list")
class TransitDriverRunListView(APIView):
    permission_classes = [IsDevice, IsTransitDriver]

    def get(self, request):
        return Response({"runs": svc.list_driver_runs(driver_owner=owner_of(request))})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_driver_runs_update")
class TransitDriverRunUpdateView(APIView):
    permission_classes = [IsDevice, IsTransitDriver]

    def patch(self, request, run_id):
        status = request.data.get("status")
        if not status:
            return Response({"detail": "status required"}, status=400)
        try:
            run = svc.advance_driver_run(
                run_id=run_id,
                driver_owner=owner_of(request),
                status=str(status),
                actor=owner_of(request),
            )
        except TransitScheduledRun.DoesNotExist:
            return Response({"detail": "run not found"}, status=404)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.scheduled_run_to_dict(run))


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_live_map")
class TransitLiveMapView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            svc.live_transit_map(
                region=request.query_params.get("region") or "Dar es Salaam",
                route_id=request.query_params.get("route_id") or "",
            )
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_avl_ping")
class TransitAvlPingView(APIView):
    permission_classes = [IsDevice, IsTransitDriver]

    def post(self, request):
        vehicle_label = request.data.get("vehicle_label")
        route_id = request.data.get("route_id")
        lat = _float_param(str(request.data.get("latitude", "")))
        lng = _float_param(str(request.data.get("longitude", "")))
        if not vehicle_label or not route_id or lat is None or lng is None:
            return Response({"detail": "vehicle_label, route_id, latitude, longitude required"}, status=400)
        try:
            vehicle = svc.upsert_avl_ping(
                actor=owner_of(request),
                vehicle_label=str(vehicle_label),
                route_id=route_id,
                latitude=lat,
                longitude=lng,
                heading=int(request.data.get("heading") or 0),
                speed_kmh=int(request.data.get("speed_kmh") or 0),
                next_stop_code=str(request.data.get("next_stop_code") or ""),
                eta_next_stop_seconds=int(request.data.get("eta_next_stop_seconds") or 0),
                status=str(request.data.get("status") or "in_service"),
            )
        except PublicTransitRoute.DoesNotExist:
            return Response({"detail": "route not found"}, status=404)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.avl_vehicle_to_dict(vehicle))


@extend_schema(tags=["mobility-transit"])
class TransitProfileView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(svc.passenger_profile_bundle(owner=owner_of(request)))

    def patch(self, request):
        try:
            profile = svc.update_passenger_profile(owner=owner_of(request), data=request.data)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.passenger_profile_bundle(owner=profile.owner))


@extend_schema(tags=["mobility-transit"])
class TransitFavoriteListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"favorites": svc.list_transit_favorites(owner=owner_of(request))})

    def post(self, request):
        try:
            fav = svc.add_transit_favorite(
                owner=owner_of(request),
                subject_type=str(request.data.get("subject_type") or ""),
                subject_code=str(request.data.get("subject_code") or ""),
                label=str(request.data.get("label") or ""),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(fav.id),
                "subject_type": fav.subject_type,
                "subject_code": fav.subject_code,
                "label": fav.label,
            },
            status=201,
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_favorites_delete")
class TransitFavoriteDeleteView(APIView):
    permission_classes = [IsDevice]

    def delete(self, request, favorite_id):
        svc.remove_transit_favorite(owner=owner_of(request), favorite_id=favorite_id)
        return Response(status=204)


@extend_schema(tags=["mobility-transit"])
class TransitNotificationListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"notifications": svc.list_transit_notifications(owner=owner_of(request))})

    def post(self, request):
        ids = request.data.get("ids") or []
        count = svc.mark_transit_notifications_read(
            owner=owner_of(request),
            notification_ids=ids if ids else None,
        )
        return Response({"marked_read": count})


@extend_schema(tags=["mobility-transit"])
class TransitFeedbackView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        rating = request.data.get("rating")
        if rating is None:
            return Response({"detail": "rating required"}, status=400)
        try:
            feedback = svc.submit_transit_feedback(
                owner=owner_of(request),
                rating=int(rating),
                comment=str(request.data.get("comment") or ""),
                tags=request.data.get("tags") or [],
                route_id=request.data.get("route_id"),
                ticket_id=request.data.get("ticket_id"),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(feedback.id),
                "rating": feedback.rating,
                "sentiment": feedback.sentiment,
            },
            status=201,
        )

    def get(self, request):
        return Response({"feedback": svc.list_transit_feedback(owner=owner_of(request))})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_safety_sos")
class TransitSafetySosView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        lat = _float_param(str(request.data.get("latitude", "")))
        lng = _float_param(str(request.data.get("longitude", "")))
        try:
            result = svc.report_transit_sos(
                owner=owner_of(request),
                latitude=lat,
                longitude=lng,
                stop_code=str(request.data.get("stop_code") or ""),
                route_id=request.data.get("route_id"),
                vehicle_label=str(request.data.get("vehicle_label") or ""),
                notes=str(request.data.get("notes") or ""),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result, status=201)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_analytics")
class TransitAnalyticsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region") or "Dar es Salaam"
        days = int(request.query_params.get("days") or 7)
        return Response(svc.transit_analytics_bundle(region=region, days=days))


@extend_schema(tags=["mobility-transit"])
class TransitAdminRouteView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request):
        try:
            route = svc.admin_upsert_route(actor=owner_of(request), data=request.data)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.route_to_dict(route), status=201)


@extend_schema(tags=["mobility-transit"])
class TransitAdminRouteDetailView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def patch(self, request, route_id):
        try:
            route = svc.admin_upsert_route(
                actor=owner_of(request),
                route_id=route_id,
                data=request.data,
            )
        except PublicTransitRoute.DoesNotExist:
            return Response({"detail": "route not found"}, status=404)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.route_to_dict(route))


@extend_schema(tags=["mobility-transit"])
class TransitAdminProductView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request):
        try:
            product = svc.admin_upsert_product(actor=owner_of(request), data=request.data)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.product_to_dict(product), status=201)


@extend_schema(tags=["mobility-transit"])
class TransitAdminProductDetailView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def patch(self, request, product_id):
        try:
            product = svc.admin_upsert_product(
                actor=owner_of(request),
                product_id=product_id,
                data=request.data,
            )
        except TransitTicketProduct.DoesNotExist:
            return Response({"detail": "product not found"}, status=404)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.product_to_dict(product))


@extend_schema(tags=["mobility-transit"])
class TransitAssistantView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        query = request.query_params.get("q") or request.query_params.get("query") or ""
        try:
            return Response(
                svc.transit_ai_assistant(
                    owner=owner_of(request),
                    query=query,
                    locale=request.query_params.get("locale") or "",
                    region=request.query_params.get("region") or "Dar es Salaam",
                    origin_stop=request.query_params.get("origin_stop") or "",
                    destination_stop=request.query_params.get("destination_stop") or "",
                )
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)

    def post(self, request):
        query = request.data.get("query") or request.data.get("q") or ""
        try:
            return Response(
                svc.transit_ai_assistant(
                    owner=owner_of(request),
                    query=str(query),
                    locale=str(request.data.get("locale") or ""),
                    region=str(request.data.get("region") or "Dar es Salaam"),
                    origin_stop=str(request.data.get("origin_stop") or ""),
                    destination_stop=str(request.data.get("destination_stop") or ""),
                )
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_family_bundle")
class TransitFamilyBundleView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(svc.transit_family_bundle(guardian_owner=owner_of(request)))


@extend_schema(tags=["mobility-transit"])
class TransitFamilyMemberListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"members": svc.list_transit_family_members(guardian_owner=owner_of(request))})

    def post(self, request):
        try:
            member = svc.add_transit_family_member(
                guardian_owner=owner_of(request),
                member_owner=str(request.data.get("member_owner") or ""),
                display_name=str(request.data.get("display_name") or ""),
                relationship=str(request.data.get("relationship") or "child"),
                monthly_limit_minor=int(request.data.get("monthly_limit_minor") or 0),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(member.id),
                "member_owner": member.member_owner,
                "display_name": member.display_name,
                "relationship": member.relationship,
            },
            status=201,
        )


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_family_member_delete")
class TransitFamilyMemberDeleteView(APIView):
    permission_classes = [IsDevice]

    def delete(self, request, member_id):
        try:
            svc.remove_transit_family_member(
                guardian_owner=owner_of(request),
                member_id=member_id,
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(status=204)


@extend_schema(tags=["mobility-transit"])
class TransitLostFoundView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        kind = str(request.query_params.get("kind") or "")
        stop_code = str(request.query_params.get("stop_code") or "")
        return Response(
            svc.transit_lost_found_bundle(
                owner=owner_of(request),
                kind=kind,
                stop_code=stop_code,
            )
        )

    def post(self, request):
        try:
            item = svc.report_transit_lost_found(
                owner=owner_of(request),
                kind=str(request.data.get("kind") or ""),
                title=str(request.data.get("title") or ""),
                description=str(request.data.get("description") or ""),
                category=str(request.data.get("category") or "other"),
                stop_code=str(request.data.get("stop_code") or ""),
                route_id=request.data.get("route_id"),
                contact_hint=str(request.data.get("contact_hint") or ""),
                photo_url=str(request.data.get("photo_url") or ""),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.lost_found_item_to_dict(item), status=201)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_lost_found_claim")
class TransitLostFoundClaimView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, item_id):
        try:
            item = svc.claim_transit_lost_found(
                item_id=item_id,
                claimant_owner=owner_of(request),
                message=str(request.data.get("message") or ""),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.lost_found_item_to_dict(item))


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_lost_found_resolve")
class TransitLostFoundResolveView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, item_id):
        try:
            item = svc.resolve_transit_lost_found(
                item_id=item_id,
                actor_owner=owner_of(request),
                status=str(request.data.get("status") or "closed"),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.lost_found_item_to_dict(item))


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_lost_found_photo")
class TransitLostFoundPhotoView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        import base64

        raw = request.data.get("content_base64") or ""
        if not raw:
            return Response({"detail": "content_base64 required"}, status=400)
        try:
            content = base64.b64decode(raw)
        except Exception:
            return Response({"detail": "invalid base64"}, status=400)
        try:
            url = svc.upload_transit_lost_found_photo(
                owner=owner_of(request),
                content=content,
                content_type=str(request.data.get("content_type") or "image/jpeg"),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response({"photo_url": url}, status=201)


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_admin_lost_found")
class TransitAdminLostFoundView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        status_filter = str(request.query_params.get("status") or "")
        return Response({"items": svc.ops_list_transit_lost_found(status=status_filter)})


@extend_schema(tags=["mobility-transit"], operation_id="mobility_transit_admin_lost_found_resolve")
class TransitAdminLostFoundResolveView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request, item_id):
        try:
            item = svc.ops_resolve_transit_lost_found(
                item_id=item_id,
                status=str(request.data.get("status") or "closed"),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(svc.lost_found_item_to_dict(item))
