from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .models import (
    AdminCase,
    ChatMessage,
    ChatThread,
    DriverJob,
    EduPayment,
    FamilyTransfer,
    FlightBooking,
    FoodOrder,
    GovRequest,
    HealthAppointment,
    HousingInquiry,
    HudumaBooking,
    InsurancePolicy,
    JobAssignment,
    MerchantOrder,
    StayBooking,
    TourBooking,
    WealthContribution,
    WingaOrder,
    WingaServiceBooking,
    WingaShopApplication,
    WingaShopStatus,
)
from .serializers import (
    AdminCaseCreateSerializer,
    AdminCasePatchSerializer,
    AdminCaseSerializer,
    ChatMessageCreateSerializer,
    ChatMessageSerializer,
    ChatThreadCreateSerializer,
    ChatThreadPatchSerializer,
    ChatThreadSerializer,
    DriverJobCreateSerializer,
    DriverJobPatchSerializer,
    DriverJobSerializer,
    EduPaymentCreateSerializer,
    EduPaymentPatchSerializer,
    EduPaymentSerializer,
    FamilyTransferCreateSerializer,
    FamilyTransferPatchSerializer,
    FamilyTransferSerializer,
    FlightBookingCreateSerializer,
    FlightBookingPatchSerializer,
    FlightBookingSerializer,
    FoodOrderCreateSerializer,
    FoodOrderPatchSerializer,
    FoodOrderSerializer,
    GovRequestCreateSerializer,
    GovRequestPatchSerializer,
    GovRequestSerializer,
    HealthAppointmentCreateSerializer,
    HealthAppointmentPatchSerializer,
    HealthAppointmentSerializer,
    HousingInquiryCreateSerializer,
    HousingInquiryPatchSerializer,
    HousingInquirySerializer,
    HudumaBookingCreateSerializer,
    HudumaBookingPatchSerializer,
    HudumaBookingSerializer,
    InsurancePolicyCreateSerializer,
    InsurancePolicyPatchSerializer,
    InsurancePolicySerializer,
    JobAssignmentCreateSerializer,
    JobAssignmentPatchSerializer,
    JobAssignmentSerializer,
    MerchantOrderCreateSerializer,
    MerchantOrderPatchSerializer,
    MerchantOrderSerializer,
    StayBookingCreateSerializer,
    StayBookingPatchSerializer,
    StayBookingSerializer,
    TourBookingCreateSerializer,
    TourBookingPatchSerializer,
    TourBookingSerializer,
    WealthContributionCreateSerializer,
    WealthContributionPatchSerializer,
    WealthContributionSerializer,
    WingaOrderCreateSerializer,
    WingaOrderPatchSerializer,
    WingaOrderSerializer,
    WingaServiceBookingCreateSerializer,
    WingaServiceBookingSerializer,
    WingaShopApplicationCreateSerializer,
    WingaShopApplicationSerializer,
)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FoodOrderSerializer(many=True), operation_id="commerce_food_orders_list"),
    post=extend_schema(tags=["commerce"], request=FoodOrderCreateSerializer, responses={201: FoodOrderSerializer}, operation_id="commerce_food_orders_create"),
)
class FoodOrderListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = FoodOrder.objects.filter(owner=request.auth.owner)[:50]
        return Response(FoodOrderSerializer(qs, many=True).data)

    def post(self, request):
        s = FoodOrderCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        order = FoodOrder.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(FoodOrderSerializer(order).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FoodOrderSerializer, operation_id="commerce_food_orders_retrieve"),
    patch=extend_schema(tags=["commerce"], request=FoodOrderPatchSerializer, responses=FoodOrderSerializer, operation_id="commerce_food_orders_partial_update"),
)
class FoodOrderDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, order_id):
        try:
            order = FoodOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except FoodOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(FoodOrderSerializer(order).data)

    def patch(self, request, order_id):
        try:
            order = FoodOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except FoodOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = FoodOrderPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(order, k, v)
        order.save()
        return Response(FoodOrderSerializer(order).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=StayBookingSerializer(many=True), operation_id="commerce_stay_bookings_list"),
    post=extend_schema(tags=["commerce"], request=StayBookingCreateSerializer, responses={201: StayBookingSerializer}, operation_id="commerce_stay_bookings_create"),
)
class StayBookingListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = StayBooking.objects.filter(owner=request.auth.owner)[:50]
        return Response(StayBookingSerializer(qs, many=True).data)

    def post(self, request):
        s = StayBookingCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        booking = StayBooking.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(StayBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=StayBookingSerializer, operation_id="commerce_stay_bookings_retrieve"),
    patch=extend_schema(tags=["commerce"], request=StayBookingPatchSerializer, responses=StayBookingSerializer, operation_id="commerce_stay_bookings_partial_update"),
)
class StayBookingDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, booking_id):
        try:
            booking = StayBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except StayBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(StayBookingSerializer(booking).data)

    def patch(self, request, booking_id):
        try:
            booking = StayBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except StayBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = StayBookingPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(booking, k, v)
        booking.save()
        return Response(StayBookingSerializer(booking).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FlightBookingSerializer(many=True), operation_id="commerce_flight_bookings_list"),
    post=extend_schema(tags=["commerce"], request=FlightBookingCreateSerializer, responses={201: FlightBookingSerializer}, operation_id="commerce_flight_bookings_create"),
)
class FlightBookingListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = FlightBooking.objects.filter(owner=request.auth.owner)[:50]
        return Response(FlightBookingSerializer(qs, many=True).data)

    def post(self, request):
        s = FlightBookingCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        booking = FlightBooking.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(FlightBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FlightBookingSerializer, operation_id="commerce_flight_bookings_retrieve"),
    patch=extend_schema(tags=["commerce"], request=FlightBookingPatchSerializer, responses=FlightBookingSerializer, operation_id="commerce_flight_bookings_partial_update"),
)
class FlightBookingDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, booking_id):
        try:
            booking = FlightBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except FlightBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(FlightBookingSerializer(booking).data)

    def patch(self, request, booking_id):
        try:
            booking = FlightBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except FlightBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = FlightBookingPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(booking, k, v)
        booking.save()
        return Response(FlightBookingSerializer(booking).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=TourBookingSerializer(many=True), operation_id="commerce_tour_bookings_list"),
    post=extend_schema(tags=["commerce"], request=TourBookingCreateSerializer, responses={201: TourBookingSerializer}, operation_id="commerce_tour_bookings_create"),
)
class TourBookingListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = TourBooking.objects.filter(owner=request.auth.owner)[:50]
        return Response(TourBookingSerializer(qs, many=True).data)

    def post(self, request):
        s = TourBookingCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        booking = TourBooking.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(TourBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=TourBookingSerializer, operation_id="commerce_tour_bookings_retrieve"),
    patch=extend_schema(tags=["commerce"], request=TourBookingPatchSerializer, responses=TourBookingSerializer, operation_id="commerce_tour_bookings_partial_update"),
)
class TourBookingDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, booking_id):
        try:
            booking = TourBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except TourBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(TourBookingSerializer(booking).data)

    def patch(self, request, booking_id):
        try:
            booking = TourBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except TourBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = TourBookingPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(booking, k, v)
        booking.save()
        return Response(TourBookingSerializer(booking).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WingaOrderSerializer(many=True), operation_id="commerce_winga_orders_list"),
    post=extend_schema(tags=["commerce"], request=WingaOrderCreateSerializer, responses={201: WingaOrderSerializer}, operation_id="commerce_winga_orders_create"),
)
class WingaOrderListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = WingaOrder.objects.filter(owner=request.auth.owner)[:50]
        return Response(WingaOrderSerializer(qs, many=True).data)

    def post(self, request):
        s = WingaOrderCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        order = WingaOrder.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(WingaOrderSerializer(order).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WingaOrderSerializer, operation_id="commerce_winga_orders_retrieve"),
    patch=extend_schema(tags=["commerce"], request=WingaOrderPatchSerializer, responses=WingaOrderSerializer, operation_id="commerce_winga_orders_partial_update"),
)
class WingaOrderDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, order_id):
        try:
            order = WingaOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except WingaOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(WingaOrderSerializer(order).data)

    def patch(self, request, order_id):
        try:
            order = WingaOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except WingaOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = WingaOrderPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(order, k, v)
        order.save()
        return Response(WingaOrderSerializer(order).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WingaServiceBookingSerializer(many=True), operation_id="commerce_winga_service_bookings_list"),
    post=extend_schema(tags=["commerce"], request=WingaServiceBookingCreateSerializer, responses={201: WingaServiceBookingSerializer}, operation_id="commerce_winga_service_bookings_create"),
)
class WingaServiceBookingListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = WingaServiceBooking.objects.filter(owner=request.auth.owner)[:50]
        return Response(WingaServiceBookingSerializer(qs, many=True).data)

    def post(self, request):
        s = WingaServiceBookingCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        booking = WingaServiceBooking.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(WingaServiceBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WingaShopApplicationSerializer(many=True), operation_id="commerce_winga_shops_list"),
    post=extend_schema(tags=["commerce"], request=WingaShopApplicationCreateSerializer, responses={201: WingaShopApplicationSerializer}, operation_id="commerce_winga_shops_create"),
)
class WingaShopApplicationListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = WingaShopApplication.objects.filter(owner=request.auth.owner)[:20]
        return Response(WingaShopApplicationSerializer(qs, many=True).data)

    def post(self, request):
        s = WingaShopApplicationCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        shop = WingaShopApplication.objects.create(
            owner=request.auth.owner,
            status=WingaShopStatus.APPROVED,
            **s.validated_data,
        )
        return Response(WingaShopApplicationSerializer(shop).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=GovRequestSerializer(many=True), operation_id="commerce_gov_requests_list"),
    post=extend_schema(tags=["commerce"], request=GovRequestCreateSerializer, responses={201: GovRequestSerializer}, operation_id="commerce_gov_requests_create"),
)
class GovRequestListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = GovRequest.objects.filter(owner=request.auth.owner)[:50]
        return Response(GovRequestSerializer(qs, many=True).data)

    def post(self, request):
        s = GovRequestCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        req = GovRequest.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(GovRequestSerializer(req).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=GovRequestSerializer, operation_id="commerce_gov_requests_retrieve"),
    patch=extend_schema(tags=["commerce"], request=GovRequestPatchSerializer, responses=GovRequestSerializer, operation_id="commerce_gov_requests_partial_update"),
)
class GovRequestDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, request_id):
        try:
            req = GovRequest.objects.get(pk=request_id, owner=request.auth.owner)
        except GovRequest.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(GovRequestSerializer(req).data)

    def patch(self, request, request_id):
        try:
            req = GovRequest.objects.get(pk=request_id, owner=request.auth.owner)
        except GovRequest.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = GovRequestPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(req, k, v)
        req.save()
        return Response(GovRequestSerializer(req).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HealthAppointmentSerializer(many=True), operation_id="commerce_health_appointments_list"),
    post=extend_schema(tags=["commerce"], request=HealthAppointmentCreateSerializer, responses={201: HealthAppointmentSerializer}, operation_id="commerce_health_appointments_create"),
)
class HealthAppointmentListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = HealthAppointment.objects.filter(owner=request.auth.owner)[:50]
        return Response(HealthAppointmentSerializer(qs, many=True).data)

    def post(self, request):
        s = HealthAppointmentCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        apt = HealthAppointment.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(HealthAppointmentSerializer(apt).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HealthAppointmentSerializer, operation_id="commerce_health_appointments_retrieve"),
    patch=extend_schema(tags=["commerce"], request=HealthAppointmentPatchSerializer, responses=HealthAppointmentSerializer, operation_id="commerce_health_appointments_partial_update"),
)
class HealthAppointmentDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, appointment_id):
        try:
            apt = HealthAppointment.objects.get(pk=appointment_id, owner=request.auth.owner)
        except HealthAppointment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(HealthAppointmentSerializer(apt).data)

    def patch(self, request, appointment_id):
        try:
            apt = HealthAppointment.objects.get(pk=appointment_id, owner=request.auth.owner)
        except HealthAppointment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = HealthAppointmentPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(apt, k, v)
        apt.save()
        return Response(HealthAppointmentSerializer(apt).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=EduPaymentSerializer(many=True), operation_id="commerce_edu_payments_list"),
    post=extend_schema(tags=["commerce"], request=EduPaymentCreateSerializer, responses={201: EduPaymentSerializer}, operation_id="commerce_edu_payments_create"),
)
class EduPaymentListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = EduPayment.objects.filter(owner=request.auth.owner)[:50]
        return Response(EduPaymentSerializer(qs, many=True).data)

    def post(self, request):
        s = EduPaymentCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        payment = EduPayment.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(EduPaymentSerializer(payment).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=EduPaymentSerializer, operation_id="commerce_edu_payments_retrieve"),
    patch=extend_schema(tags=["commerce"], request=EduPaymentPatchSerializer, responses=EduPaymentSerializer, operation_id="commerce_edu_payments_partial_update"),
)
class EduPaymentDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, payment_id):
        try:
            payment = EduPayment.objects.get(pk=payment_id, owner=request.auth.owner)
        except EduPayment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(EduPaymentSerializer(payment).data)

    def patch(self, request, payment_id):
        try:
            payment = EduPayment.objects.get(pk=payment_id, owner=request.auth.owner)
        except EduPayment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = EduPaymentPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(payment, k, v)
        payment.save()
        return Response(EduPaymentSerializer(payment).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HousingInquirySerializer(many=True), operation_id="commerce_housing_inquiries_list"),
    post=extend_schema(tags=["commerce"], request=HousingInquiryCreateSerializer, responses={201: HousingInquirySerializer}, operation_id="commerce_housing_inquiries_create"),
)
class HousingInquiryListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = HousingInquiry.objects.filter(owner=request.auth.owner)[:50]
        return Response(HousingInquirySerializer(qs, many=True).data)

    def post(self, request):
        s = HousingInquiryCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        inquiry = HousingInquiry.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(HousingInquirySerializer(inquiry).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HousingInquirySerializer, operation_id="commerce_housing_inquiries_retrieve"),
    patch=extend_schema(tags=["commerce"], request=HousingInquiryPatchSerializer, responses=HousingInquirySerializer, operation_id="commerce_housing_inquiries_partial_update"),
)
class HousingInquiryDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, inquiry_id):
        try:
            inquiry = HousingInquiry.objects.get(pk=inquiry_id, owner=request.auth.owner)
        except HousingInquiry.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(HousingInquirySerializer(inquiry).data)

    def patch(self, request, inquiry_id):
        try:
            inquiry = HousingInquiry.objects.get(pk=inquiry_id, owner=request.auth.owner)
        except HousingInquiry.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = HousingInquiryPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(inquiry, k, v)
        inquiry.save()
        return Response(HousingInquirySerializer(inquiry).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WealthContributionSerializer(many=True), operation_id="commerce_wealth_contributions_list"),
    post=extend_schema(tags=["commerce"], request=WealthContributionCreateSerializer, responses={201: WealthContributionSerializer}, operation_id="commerce_wealth_contributions_create"),
)
class WealthContributionListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = WealthContribution.objects.filter(owner=request.auth.owner)[:50]
        return Response(WealthContributionSerializer(qs, many=True).data)

    def post(self, request):
        s = WealthContributionCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        data = dict(s.validated_data)
        contrib = WealthContribution.objects.create(owner=request.auth.owner, **data)
        return Response(WealthContributionSerializer(contrib).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=WealthContributionSerializer, operation_id="commerce_wealth_contributions_retrieve"),
    patch=extend_schema(tags=["commerce"], request=WealthContributionPatchSerializer, responses=WealthContributionSerializer, operation_id="commerce_wealth_contributions_partial_update"),
)
class WealthContributionDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, contribution_id):
        try:
            contrib = WealthContribution.objects.get(pk=contribution_id, owner=request.auth.owner)
        except WealthContribution.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(WealthContributionSerializer(contrib).data)

    def patch(self, request, contribution_id):
        try:
            contrib = WealthContribution.objects.get(pk=contribution_id, owner=request.auth.owner)
        except WealthContribution.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = WealthContributionPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(contrib, k, v)
        contrib.save()
        return Response(WealthContributionSerializer(contrib).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=JobAssignmentSerializer(many=True), operation_id="commerce_job_assignments_list"),
    post=extend_schema(tags=["commerce"], request=JobAssignmentCreateSerializer, responses={201: JobAssignmentSerializer}, operation_id="commerce_job_assignments_create"),
)
class JobAssignmentListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = JobAssignment.objects.filter(owner=request.auth.owner)[:50]
        return Response(JobAssignmentSerializer(qs, many=True).data)

    def post(self, request):
        s = JobAssignmentCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        assignment = JobAssignment.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(JobAssignmentSerializer(assignment).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=JobAssignmentSerializer, operation_id="commerce_job_assignments_retrieve"),
    patch=extend_schema(tags=["commerce"], request=JobAssignmentPatchSerializer, responses=JobAssignmentSerializer, operation_id="commerce_job_assignments_partial_update"),
)
class JobAssignmentDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, assignment_id):
        try:
            assignment = JobAssignment.objects.get(pk=assignment_id, owner=request.auth.owner)
        except JobAssignment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(JobAssignmentSerializer(assignment).data)

    def patch(self, request, assignment_id):
        try:
            assignment = JobAssignment.objects.get(pk=assignment_id, owner=request.auth.owner)
        except JobAssignment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = JobAssignmentPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(assignment, k, v)
        assignment.save()
        return Response(JobAssignmentSerializer(assignment).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=InsurancePolicySerializer(many=True), operation_id="commerce_insurance_policies_list"),
    post=extend_schema(tags=["commerce"], request=InsurancePolicyCreateSerializer, responses={201: InsurancePolicySerializer}, operation_id="commerce_insurance_policies_create"),
)
class InsurancePolicyListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = InsurancePolicy.objects.filter(owner=request.auth.owner)[:50]
        return Response(InsurancePolicySerializer(qs, many=True).data)

    def post(self, request):
        s = InsurancePolicyCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        policy = InsurancePolicy.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(InsurancePolicySerializer(policy).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=InsurancePolicySerializer, operation_id="commerce_insurance_policies_retrieve"),
    patch=extend_schema(tags=["commerce"], request=InsurancePolicyPatchSerializer, responses=InsurancePolicySerializer, operation_id="commerce_insurance_policies_partial_update"),
)
class InsurancePolicyDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, policy_id):
        try:
            policy = InsurancePolicy.objects.get(pk=policy_id, owner=request.auth.owner)
        except InsurancePolicy.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(InsurancePolicySerializer(policy).data)

    def patch(self, request, policy_id):
        try:
            policy = InsurancePolicy.objects.get(pk=policy_id, owner=request.auth.owner)
        except InsurancePolicy.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = InsurancePolicyPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(policy, k, v)
        policy.save()
        return Response(InsurancePolicySerializer(policy).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FamilyTransferSerializer(many=True), operation_id="commerce_family_transfers_list"),
    post=extend_schema(tags=["commerce"], request=FamilyTransferCreateSerializer, responses={201: FamilyTransferSerializer}, operation_id="commerce_family_transfers_create"),
)
class FamilyTransferListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = FamilyTransfer.objects.filter(owner=request.auth.owner)[:50]
        return Response(FamilyTransferSerializer(qs, many=True).data)

    def post(self, request):
        s = FamilyTransferCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        transfer = FamilyTransfer.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(FamilyTransferSerializer(transfer).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=FamilyTransferSerializer, operation_id="commerce_family_transfers_retrieve"),
    patch=extend_schema(tags=["commerce"], request=FamilyTransferPatchSerializer, responses=FamilyTransferSerializer, operation_id="commerce_family_transfers_partial_update"),
)
class FamilyTransferDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, transfer_id):
        try:
            transfer = FamilyTransfer.objects.get(pk=transfer_id, owner=request.auth.owner)
        except FamilyTransfer.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(FamilyTransferSerializer(transfer).data)

    def patch(self, request, transfer_id):
        try:
            transfer = FamilyTransfer.objects.get(pk=transfer_id, owner=request.auth.owner)
        except FamilyTransfer.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = FamilyTransferPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(transfer, k, v)
        transfer.save()
        return Response(FamilyTransferSerializer(transfer).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HudumaBookingSerializer(many=True), operation_id="commerce_huduma_bookings_list"),
    post=extend_schema(tags=["commerce"], request=HudumaBookingCreateSerializer, responses={201: HudumaBookingSerializer}, operation_id="commerce_huduma_bookings_create"),
)
class HudumaBookingListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = HudumaBooking.objects.filter(owner=request.auth.owner)[:50]
        return Response(HudumaBookingSerializer(qs, many=True).data)

    def post(self, request):
        s = HudumaBookingCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        booking = HudumaBooking.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(HudumaBookingSerializer(booking).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=HudumaBookingSerializer, operation_id="commerce_huduma_bookings_retrieve"),
    patch=extend_schema(tags=["commerce"], request=HudumaBookingPatchSerializer, responses=HudumaBookingSerializer, operation_id="commerce_huduma_bookings_partial_update"),
)
class HudumaBookingDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, booking_id):
        try:
            booking = HudumaBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except HudumaBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(HudumaBookingSerializer(booking).data)

    def patch(self, request, booking_id):
        try:
            booking = HudumaBooking.objects.get(pk=booking_id, owner=request.auth.owner)
        except HudumaBooking.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = HudumaBookingPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(booking, k, v)
        booking.save()
        return Response(HudumaBookingSerializer(booking).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=MerchantOrderSerializer(many=True), operation_id="commerce_merchant_orders_list"),
    post=extend_schema(tags=["commerce"], request=MerchantOrderCreateSerializer, responses={201: MerchantOrderSerializer}, operation_id="commerce_merchant_orders_create"),
)
class MerchantOrderListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = MerchantOrder.objects.filter(owner=request.auth.owner)[:50]
        return Response(MerchantOrderSerializer(qs, many=True).data)

    def post(self, request):
        s = MerchantOrderCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        order = MerchantOrder.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(MerchantOrderSerializer(order).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=MerchantOrderSerializer, operation_id="commerce_merchant_orders_retrieve"),
    patch=extend_schema(tags=["commerce"], request=MerchantOrderPatchSerializer, responses=MerchantOrderSerializer, operation_id="commerce_merchant_orders_partial_update"),
)
class MerchantOrderDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, order_id):
        try:
            order = MerchantOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except MerchantOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(MerchantOrderSerializer(order).data)

    def patch(self, request, order_id):
        try:
            order = MerchantOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except MerchantOrder.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = MerchantOrderPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(order, k, v)
        order.save()
        return Response(MerchantOrderSerializer(order).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=DriverJobSerializer(many=True), operation_id="commerce_driver_jobs_list"),
    post=extend_schema(tags=["commerce"], request=DriverJobCreateSerializer, responses={201: DriverJobSerializer}, operation_id="commerce_driver_jobs_create"),
)
class DriverJobListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = DriverJob.objects.filter(owner=request.auth.owner)[:50]
        return Response(DriverJobSerializer(qs, many=True).data)

    def post(self, request):
        s = DriverJobCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        job = DriverJob.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(DriverJobSerializer(job).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=DriverJobSerializer, operation_id="commerce_driver_jobs_retrieve"),
    patch=extend_schema(tags=["commerce"], request=DriverJobPatchSerializer, responses=DriverJobSerializer, operation_id="commerce_driver_jobs_partial_update"),
)
class DriverJobDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, job_id):
        try:
            job = DriverJob.objects.get(pk=job_id, owner=request.auth.owner)
        except DriverJob.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(DriverJobSerializer(job).data)

    def patch(self, request, job_id):
        try:
            job = DriverJob.objects.get(pk=job_id, owner=request.auth.owner)
        except DriverJob.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = DriverJobPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(job, k, v)
        job.save()
        return Response(DriverJobSerializer(job).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=ChatThreadSerializer(many=True), operation_id="commerce_chat_threads_list"),
    post=extend_schema(tags=["commerce"], request=ChatThreadCreateSerializer, responses={201: ChatThreadSerializer}, operation_id="commerce_chat_threads_create"),
)
class ChatThreadListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = ChatThread.objects.filter(owner=request.auth.owner)[:50]
        return Response(ChatThreadSerializer(qs, many=True).data)

    def post(self, request):
        s = ChatThreadCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        thread = ChatThread.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(ChatThreadSerializer(thread).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=ChatThreadSerializer, operation_id="commerce_chat_threads_retrieve"),
    patch=extend_schema(tags=["commerce"], request=ChatThreadPatchSerializer, responses=ChatThreadSerializer, operation_id="commerce_chat_threads_partial_update"),
)
class ChatThreadDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, thread_id):
        try:
            thread = ChatThread.objects.get(pk=thread_id, owner=request.auth.owner)
        except ChatThread.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(ChatThreadSerializer(thread).data)

    def patch(self, request, thread_id):
        try:
            thread = ChatThread.objects.get(pk=thread_id, owner=request.auth.owner)
        except ChatThread.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = ChatThreadPatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(thread, k, v)
        thread.save()
        return Response(ChatThreadSerializer(thread).data)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=ChatMessageSerializer(many=True), operation_id="commerce_chat_messages_list"),
    post=extend_schema(tags=["commerce"], request=ChatMessageCreateSerializer, responses={201: ChatMessageSerializer}, operation_id="commerce_chat_messages_create"),
)
class ChatMessageListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, thread_id):
        try:
            thread = ChatThread.objects.get(pk=thread_id, owner=request.auth.owner)
        except ChatThread.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        qs = ChatMessage.objects.filter(owner=request.auth.owner, thread=thread)[:200]
        return Response(ChatMessageSerializer(qs, many=True).data)

    def post(self, request, thread_id):
        try:
            thread = ChatThread.objects.get(pk=thread_id, owner=request.auth.owner)
        except ChatThread.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = ChatMessageCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        msg = ChatMessage.objects.create(
            owner=request.auth.owner,
            thread=thread,
            **s.validated_data,
        )
        thread.subtitle = msg.text[:255]
        thread.unread = 0
        thread.save(update_fields=["subtitle", "unread", "updated_at"])
        return Response(ChatMessageSerializer(msg).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=AdminCaseSerializer(many=True), operation_id="commerce_admin_cases_list"),
    post=extend_schema(tags=["commerce"], request=AdminCaseCreateSerializer, responses={201: AdminCaseSerializer}, operation_id="commerce_admin_cases_create"),
)
class AdminCaseListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = AdminCase.objects.filter(owner=request.auth.owner)[:50]
        return Response(AdminCaseSerializer(qs, many=True).data)

    def post(self, request):
        s = AdminCaseCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        case = AdminCase.objects.create(owner=request.auth.owner, **s.validated_data)
        return Response(AdminCaseSerializer(case).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["commerce"], responses=AdminCaseSerializer, operation_id="commerce_admin_cases_retrieve"),
    patch=extend_schema(tags=["commerce"], request=AdminCasePatchSerializer, responses=AdminCaseSerializer, operation_id="commerce_admin_cases_partial_update"),
)
class AdminCaseDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, case_id):
        try:
            case = AdminCase.objects.get(pk=case_id, owner=request.auth.owner)
        except AdminCase.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(AdminCaseSerializer(case).data)

    def patch(self, request, case_id):
        try:
            case = AdminCase.objects.get(pk=case_id, owner=request.auth.owner)
        except AdminCase.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = AdminCasePatchSerializer(data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        for k, v in s.validated_data.items():
            setattr(case, k, v)
        case.save()
        return Response(AdminCaseSerializer(case).data)


def _commerce_pay(request, collector, pk, serializer_cls):
    """Shared POST …/pay handler: Idempotency-Key + ledger capture."""
    from django.core.exceptions import ObjectDoesNotExist

    from .services import CommerceError

    key = request.headers.get("Idempotency-Key", "").strip()
    if not key:
        return Response({"detail": "Idempotency-Key required"}, status=400)
    try:
        obj = collector(
            pk,
            owner=request.auth.owner,
            actor=request.auth.owner,
            idempotency_key=key,
        )
    except CommerceError as exc:
        return Response({"detail": str(exc)}, status=409)
    except ObjectDoesNotExist:
        return Response({"detail": "Not found."}, status=404)
    return Response(serializer_cls(obj).data)


@extend_schema(tags=["commerce-payments"], request=None, responses=FoodOrderSerializer)
class FoodOrderPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        from . import services

        return _commerce_pay(
            request, services.collect_food_order_payment, order_id, FoodOrderSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=StayBookingSerializer)
class StayBookingPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, booking_id):
        from . import services

        return _commerce_pay(
            request, services.collect_stay_booking_payment, booking_id, StayBookingSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=FlightBookingSerializer)
class FlightBookingPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, booking_id):
        from . import services

        return _commerce_pay(
            request,
            services.collect_flight_booking_payment,
            booking_id,
            FlightBookingSerializer,
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=TourBookingSerializer)
class TourBookingPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, booking_id):
        from . import services

        return _commerce_pay(
            request, services.collect_tour_booking_payment, booking_id, TourBookingSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=GovRequestSerializer)
class GovRequestPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, request_id):
        from . import services

        return _commerce_pay(
            request, services.collect_gov_request_payment, request_id, GovRequestSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=HealthAppointmentSerializer)
class HealthAppointmentPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, appointment_id):
        from . import services

        return _commerce_pay(
            request,
            services.collect_health_appointment_payment,
            appointment_id,
            HealthAppointmentSerializer,
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=EduPaymentSerializer)
class EduPaymentPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, payment_id):
        from . import services

        return _commerce_pay(
            request, services.collect_edu_payment, payment_id, EduPaymentSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=WingaOrderSerializer)
class WingaOrderPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        from . import services

        return _commerce_pay(
            request, services.collect_winga_order_payment, order_id, WingaOrderSerializer
        )


@extend_schema(tags=["commerce-payments"], request=None, responses=HousingInquirySerializer)
class HousingInquiryPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, inquiry_id):
        from . import services

        return _commerce_pay(
            request,
            services.collect_housing_deposit_payment,
            inquiry_id,
            HousingInquirySerializer,
        )
