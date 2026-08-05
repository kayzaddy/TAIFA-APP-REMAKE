import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';

class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.title,
    required this.description,
    required this.transactionType,
    required this.categoryCode,
    required this.propertyTypeCode,
    required this.price,
    required this.deposit,
    required this.beds,
    required this.baths,
    required this.areaSqm,
    required this.region,
    required this.district,
    required this.ward,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.verificationStatus,
    required this.primaryPhotoUrl,
    required this.media,
    this.ownerName = '',
    this.isUnlocked = false,
    this.ownerPhone = '',
    this.ownerEmail = '',
  });

  final String id;
  final String title;
  final String description;
  final String transactionType;
  final String categoryCode;
  final String propertyTypeCode;
  final Money price;
  final Money deposit;
  final int beds;
  final int baths;
  final int areaSqm;
  final String region;
  final String district;
  final String ward;
  final String addressLine;
  final double latitude;
  final double longitude;
  final String verificationStatus;
  final String primaryPhotoUrl;
  final List<PropertyMedia> media;
  final String ownerName;
  final bool isUnlocked;
  final String ownerPhone;
  final String ownerEmail;

  String get locationLabel => [ward, district, region].where((s) => s.isNotEmpty).join(', ');

  bool get isVerified => verificationStatus == 'verified';
}

class PropertyExperience {
  const PropertyExperience({
    required this.gallery,
    required this.walkthrough,
    required this.videoTours,
    required this.floorPlans,
    required this.panoramas360,
    required this.vrReady,
  });

  final List<PropertyMedia> gallery;
  final List<PropertyWalkthroughRoom> walkthrough;
  final List<PropertyMedia> videoTours;
  final List<PropertyFloorPlan> floorPlans;
  final List<PropertyPanorama> panoramas360;
  final bool vrReady;

  factory PropertyExperience.fromJson(Map<String, dynamic> json) {
    List<PropertyMedia> mediaList(List? raw) => raw is List
        ? raw.whereType<Map>().map((e) => PropertyMedia.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PropertyMedia>[];
    final walkRaw = json['walkthrough'];
    final walkthrough = walkRaw is List
        ? walkRaw.whereType<Map>().map((e) => PropertyWalkthroughRoom.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PropertyWalkthroughRoom>[];
    return PropertyExperience(
      gallery: mediaList(json['gallery'] as List?),
      walkthrough: walkthrough,
      videoTours: mediaList(json['video_tours'] as List?),
      floorPlans: (json['floor_plans'] as List?)
              ?.whereType<Map>()
              .map((e) => PropertyFloorPlan.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      panoramas360: (json['panoramas_360'] as List?)
              ?.whereType<Map>()
              .map((e) => PropertyPanorama.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      vrReady: json['vr_ready'] == true,
    );
  }
}

class PropertyWalkthroughRoom {
  const PropertyWalkthroughRoom({
    required this.roomCode,
    required this.label,
    required this.media,
  });

  final String roomCode;
  final String label;
  final List<PropertyMedia> media;

  factory PropertyWalkthroughRoom.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    return PropertyWalkthroughRoom(
      roomCode: json['room_code']?.toString() ?? '',
      label: json['label']?.toString() ?? json['room_code']?.toString() ?? '',
      media: mediaRaw is List
          ? mediaRaw.whereType<Map>().map((e) => PropertyMedia.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
    );
  }
}

class PropertyFloorPlan {
  const PropertyFloorPlan({required this.url, required this.caption, required this.data});

  final String url;
  final String caption;
  final Map<String, dynamic> data;

  factory PropertyFloorPlan.fromJson(Map<String, dynamic> json) {
    return PropertyFloorPlan(
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      data: json['floor_plan_data'] is Map
          ? Map<String, dynamic>.from(json['floor_plan_data'] as Map)
          : {},
    );
  }
}

class PropertyPanorama {
  const PropertyPanorama({required this.url, required this.panoramaUrl, required this.caption});

  final String url;
  final String panoramaUrl;
  final String caption;

  factory PropertyPanorama.fromJson(Map<String, dynamic> json) {
    return PropertyPanorama(
      url: json['url']?.toString() ?? '',
      panoramaUrl: json['panorama_url']?.toString() ?? json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
    );
  }
}

class ViewingPassPlan {
  const ViewingPassPlan({
    required this.code,
    required this.name,
    required this.description,
    required this.amountMinor,
    required this.currency,
    required this.listingQuota,
    required this.durationDays,
  });

  final String code;
  final String name;
  final String description;
  final int amountMinor;
  final String currency;
  final int listingQuota;
  final int durationDays;

  factory ViewingPassPlan.fromJson(Map<String, dynamic> json) {
    return ViewingPassPlan(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TZS',
      listingQuota: (json['listing_quota'] as num?)?.toInt() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class PropertyViewingPass {
  const PropertyViewingPass({
    required this.id,
    required this.planCode,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.qrToken,
    required this.isUnlocked,
    this.listingId,
    this.paymentRef = '',
    this.expiresAt,
  });

  final String id;
  final String? listingId;
  final String planCode;
  final String status;
  final int amountMinor;
  final String currency;
  final String qrToken;
  final String paymentRef;
  final bool isUnlocked;
  final DateTime? expiresAt;

  bool get isActive => status == 'active';

  factory PropertyViewingPass.fromJson(Map<String, dynamic> json) {
    return PropertyViewingPass(
      id: json['id'].toString(),
      listingId: json['listing_id']?.toString(),
      planCode: json['plan_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TZS',
      qrToken: json['qr_token']?.toString() ?? '',
      paymentRef: json['payment_ref']?.toString() ?? '',
      isUnlocked: json['unlock_address'] == true,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
    );
  }
}

class PropertyLiveSession {
  const PropertyLiveSession({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.status,
    required this.joinCode,
    this.streamUrl = '',
    this.recordingUrl = '',
    this.aiTranscriptSummary = '',
    this.scheduledAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String status;
  final String joinCode;
  final String streamUrl;
  final String recordingUrl;
  final String aiTranscriptSummary;
  final DateTime? scheduledAt;

  bool get isLive => status == 'live';

  factory PropertyLiveSession.fromJson(Map<String, dynamic> json) {
    final transcript = json['ai_transcript'];
    return PropertyLiveSession(
      id: json['id'].toString(),
      listingId: json['listing_id']?.toString() ?? '',
      listingTitle: json['listing_title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      joinCode: json['join_code']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString() ?? '',
      recordingUrl: json['recording_url']?.toString() ?? '',
      aiTranscriptSummary: transcript is Map ? transcript['summary']?.toString() ?? '' : '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
    );
  }
}

class PropertyMedia {
  const PropertyMedia({
    required this.kind,
    required this.url,
    this.caption = '',
    this.isPrimary = false,
    this.roomCode = '',
    this.tourKind = 'gallery',
    this.isHd = false,
  });

  final String kind;
  final String url;
  final String caption;
  final bool isPrimary;
  final String roomCode;
  final String tourKind;
  final bool isHd;

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      kind: json['kind']?.toString() ?? 'photo',
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
      roomCode: json['room_code']?.toString() ?? '',
      tourKind: json['tour_kind']?.toString() ?? 'gallery',
      isHd: json['is_hd'] == true,
    );
  }
}

class PropertyMapPin {
  const PropertyMapPin({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    required this.price,
    required this.beds,
    required this.transactionType,
  });

  final String id;
  final String title;
  final double lat;
  final double lng;
  final Money price;
  final int beds;
  final String transactionType;
}

class PropertyCategory {
  const PropertyCategory({required this.code, required this.name, this.icon = ''});
  final String code;
  final String name;
  final String icon;
}

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
  });

  final String id;
  final String name;
  final Map<String, dynamic> filters;
}

class PropertyNeighborhoodIntel {
  const PropertyNeighborhoodIntel({
    required this.lifestyle,
    required this.walkabilityE4,
    required this.safetyScoreE4,
    required this.waterReliabilityE4,
    required this.powerReliabilityE4,
    required this.nearby,
    this.nearestStation = '',
    this.stationDistanceMeters,
  });

  final String lifestyle;
  final int walkabilityE4;
  final int safetyScoreE4;
  final int waterReliabilityE4;
  final int powerReliabilityE4;
  final Map<String, int> nearby;
  final String nearestStation;
  final int? stationDistanceMeters;

  factory PropertyNeighborhoodIntel.fromJson(Map<String, dynamic> json) {
    final nearbyRaw = json['nearby'];
    final nearby = <String, int>{};
    if (nearbyRaw is Map) {
      nearbyRaw.forEach((k, v) {
        nearby[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    final mobility = json['mobility'];
    return PropertyNeighborhoodIntel(
      lifestyle: json['lifestyle']?.toString() ?? '',
      walkabilityE4: (json['walkability_e4'] as num?)?.toInt() ?? 0,
      safetyScoreE4: (json['safety_score_e4'] as num?)?.toInt() ?? 0,
      waterReliabilityE4: (json['water_reliability_e4'] as num?)?.toInt() ?? 0,
      powerReliabilityE4: (json['power_reliability_e4'] as num?)?.toInt() ?? 0,
      nearby: nearby,
      nearestStation: mobility is Map ? mobility['nearest_station']?.toString() ?? '' : '',
      stationDistanceMeters: mobility is Map
          ? (mobility['station_distance_meters'] as num?)?.toInt()
          : null,
    );
  }
}

class PropertyVisitScore {
  const PropertyVisitScore({
    required this.stars,
    required this.label,
    required this.scoreE4,
  });

  final int stars;
  final String label;
  final int scoreE4;

  factory PropertyVisitScore.fromJson(Map<String, dynamic> json) {
    return PropertyVisitScore(
      stars: (json['stars'] as num?)?.toInt() ?? 3,
      label: json['label']?.toString() ?? '',
      scoreE4: (json['score_e4'] as num?)?.toInt() ?? 0,
    );
  }
}

class PropertyCommuteEstimate {
  const PropertyCommuteEstimate({
    required this.durationSeconds,
    required this.durationLabel,
    required this.distanceMeters,
    required this.mode,
  });

  final int durationSeconds;
  final String durationLabel;
  final int distanceMeters;
  final String mode;

  factory PropertyCommuteEstimate.fromJson(Map<String, dynamic> json) {
    return PropertyCommuteEstimate(
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      durationLabel: json['duration_label']?.toString() ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
      mode: json['mode']?.toString() ?? 'driving',
    );
  }
}

class PropertyCompareRow {
  const PropertyCompareRow({
    required this.id,
    required this.title,
    required this.price,
    required this.beds,
    required this.baths,
    required this.areaSqm,
    required this.location,
    required this.visitStars,
    required this.visitLabel,
    required this.safetyE4,
    required this.walkabilityE4,
    required this.isVerified,
  });

  final String id;
  final String title;
  final Money price;
  final int beds;
  final int baths;
  final int areaSqm;
  final String location;
  final int visitStars;
  final String visitLabel;
  final int safetyE4;
  final int walkabilityE4;
  final bool isVerified;

  factory PropertyCompareRow.fromJson(Map<String, dynamic> json) {
    return PropertyCompareRow(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      price: Money(
        (json['price_minor'] as num?)?.toInt() ?? 0,
        Currency.fromCode(json['currency']?.toString() ?? 'TZS'),
      ),
      beds: (json['beds'] as num?)?.toInt() ?? 0,
      baths: (json['baths'] as num?)?.toInt() ?? 0,
      areaSqm: (json['area_sqm'] as num?)?.toInt() ?? 0,
      location: json['location']?.toString() ?? '',
      visitStars: (json['visit_stars'] as num?)?.toInt() ?? 3,
      visitLabel: json['visit_label']?.toString() ?? '',
      safetyE4: (json['safety_e4'] as num?)?.toInt() ?? 0,
      walkabilityE4: (json['walkability_e4'] as num?)?.toInt() ?? 0,
      isVerified: json['verification_status']?.toString() == 'verified',
    );
  }
}

class PropertyMapCluster {
  const PropertyMapCluster({
    required this.clusterId,
    required this.lat,
    required this.lng,
    required this.count,
    required this.pins,
  });

  final String clusterId;
  final double lat;
  final double lng;
  final int count;
  final List<PropertyMapPin> pins;

  factory PropertyMapCluster.fromJson(Map<String, dynamic> json) {
    final pinsRaw = json['pins'];
    final pins = pinsRaw is List
        ? pinsRaw.whereType<Map>().map((e) {
            final m = Map<String, dynamic>.from(e);
            return PropertyMapPin(
              id: m['id'].toString(),
              title: m['title']?.toString() ?? '',
              lat: (m['lat'] as num?)?.toDouble() ?? 0,
              lng: (m['lng'] as num?)?.toDouble() ?? 0,
              price: Money(
                (m['price_minor'] as num?)?.toInt() ?? 0,
                Currency.fromCode(m['currency']?.toString() ?? 'TZS'),
              ),
              beds: (m['beds'] as num?)?.toInt() ?? 0,
              transactionType: m['transaction_type']?.toString() ?? 'rent',
            );
          }).toList()
        : <PropertyMapPin>[];
    return PropertyMapCluster(
      clusterId: json['cluster_id']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? pins.length,
      pins: pins,
    );
  }
}

class PropertyWingaProfile {
  const PropertyWingaProfile({
    required this.id,
    required this.displayName,
    required this.certification,
    required this.reputationScoreE4,
    required this.trustStars,
    this.bio = '',
  });

  final String id;
  final String displayName;
  final String certification;
  final int reputationScoreE4;
  final int trustStars;
  final String bio;

  factory PropertyWingaProfile.fromJson(Map<String, dynamic> json) {
    return PropertyWingaProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      certification: json['certification']?.toString() ?? '',
      reputationScoreE4: (json['reputation_score_e4'] as num?)?.toInt() ?? 0,
      trustStars: (json['trust_stars'] as num?)?.toInt() ?? 3,
      bio: json['bio']?.toString() ?? '',
    );
  }
}

class PropertyWingaAssignment {
  const PropertyWingaAssignment({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.status,
    required this.winga,
    this.chatMessages = const [],
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String status;
  final PropertyWingaProfile winga;
  final List<PropertySecureChatMessage> chatMessages;

  factory PropertyWingaAssignment.fromJson(Map<String, dynamic> json) {
    final wingaRaw = json['winga'];
    return PropertyWingaAssignment(
      id: json['id'].toString(),
      listingId: json['listing_id']?.toString() ?? '',
      listingTitle: json['listing_title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      winga: wingaRaw is Map
          ? PropertyWingaProfile.fromJson(Map<String, dynamic>.from(wingaRaw))
          : const PropertyWingaProfile(
              id: '',
              displayName: 'Winga',
              certification: '',
              reputationScoreE4: 0,
              trustStars: 3,
            ),
    );
  }
}

class PropertySecureChatMessage {
  const PropertySecureChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
  });

  final String id;
  final String text;
  final bool isMe;

  factory PropertySecureChatMessage.fromJson(Map<String, dynamic> json) {
    return PropertySecureChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isMe: json['is_me'] == true,
    );
  }
}

class PropertyApplication {
  const PropertyApplication({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.status,
    required this.monthlyIncomeMinor,
    required this.nationalIdMasked,
    required this.verifications,
    required this.documents,
    required this.readyForApproval,
    this.lease,
    this.employmentStatus = '',
    this.notes = '',
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String status;
  final int monthlyIncomeMinor;
  final String nationalIdMasked;
  final Map<String, PropertyVerificationCheck> verifications;
  final List<PropertyApplicationDocument> documents;
  final bool readyForApproval;
  final PropertyLease? lease;
  final String employmentStatus;
  final String notes;

  bool get identityVerified =>
      verifications['identity']?.status == 'verified';
  bool get incomeVerified => verifications['income']?.status == 'verified';

  factory PropertyApplication.fromJson(Map<String, dynamic> json) {
    final verRaw = json['verifications'];
    final verifications = <String, PropertyVerificationCheck>{};
    if (verRaw is Map) {
      for (final entry in verRaw.entries) {
        if (entry.value is Map) {
          verifications[entry.key.toString()] = PropertyVerificationCheck.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    final docsRaw = json['documents'];
    final documents = docsRaw is List
        ? docsRaw
            .whereType<Map>()
            .map((e) => PropertyApplicationDocument.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PropertyApplicationDocument>[];
    final leaseRaw = json['lease'];
    return PropertyApplication(
      id: json['id'].toString(),
      listingId: json['listing_id']?.toString() ?? '',
      listingTitle: json['listing_title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      monthlyIncomeMinor: (json['monthly_income_minor'] as num?)?.toInt() ?? 0,
      nationalIdMasked: json['national_id_masked']?.toString() ?? '',
      verifications: verifications,
      documents: documents,
      readyForApproval: json['ready_for_approval'] == true,
      lease: leaseRaw is Map ? PropertyLease.fromJson(Map<String, dynamic>.from(leaseRaw)) : null,
      employmentStatus: json['employment_status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class PropertyVerificationCheck {
  const PropertyVerificationCheck({required this.status, this.providerRef = ''});

  final String status;
  final String providerRef;

  factory PropertyVerificationCheck.fromJson(Map<String, dynamic> json) {
    return PropertyVerificationCheck(
      status: json['status']?.toString() ?? 'pending',
      providerRef: json['provider_ref']?.toString() ?? '',
    );
  }
}

class PropertyApplicationDocument {
  const PropertyApplicationDocument({
    required this.id,
    required this.kind,
    required this.title,
    required this.url,
  });

  final String id;
  final String kind;
  final String title;
  final String url;

  factory PropertyApplicationDocument.fromJson(Map<String, dynamic> json) {
    return PropertyApplicationDocument(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class PropertyLease {
  const PropertyLease({
    required this.id,
    required this.applicationId,
    required this.status,
    required this.rent,
    required this.deposit,
    required this.startDate,
    required this.endDate,
    required this.contractText,
    required this.payments,
    required this.moveWorkflows,
    this.tenantSigned = false,
    this.ownerSigned = false,
  });

  final String id;
  final String applicationId;
  final String status;
  final Money rent;
  final Money deposit;
  final String startDate;
  final String endDate;
  final String contractText;
  final List<PropertyLeasePayment> payments;
  final List<PropertyMoveWorkflow> moveWorkflows;
  final bool tenantSigned;
  final bool ownerSigned;

  bool get isActive => status == 'active';
  bool get pendingSignatures => status == 'pending_signatures';

  factory PropertyLease.fromJson(Map<String, dynamic> json) {
    final currency = Currency.fromCode(json['currency']?.toString() ?? 'TZS');
    final paymentsRaw = json['payments'];
    final moveRaw = json['move_workflows'];
    return PropertyLease(
      id: json['id'].toString(),
      applicationId: json['application_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      rent: Money((json['rent_minor'] as num?)?.toInt() ?? 0, currency),
      deposit: Money((json['deposit_minor'] as num?)?.toInt() ?? 0, currency),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      contractText: json['contract_text']?.toString() ?? '',
      payments: paymentsRaw is List
          ? paymentsRaw
              .whereType<Map>()
              .map((e) => PropertyLeasePayment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      moveWorkflows: moveRaw is List
          ? moveRaw
              .whereType<Map>()
              .map((e) => PropertyMoveWorkflow.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      tenantSigned: json['tenant_signed_at'] != null,
      ownerSigned: json['owner_signed_at'] != null,
    );
  }
}

class PropertyLeasePayment {
  const PropertyLeasePayment({
    required this.id,
    required this.kind,
    required this.status,
    required this.amount,
    this.dueDate = '',
  });

  final String id;
  final String kind;
  final String status;
  final Money amount;
  final String dueDate;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending_payment';

  factory PropertyLeasePayment.fromJson(Map<String, dynamic> json) {
    final currency = Currency.fromCode(json['currency']?.toString() ?? 'TZS');
    return PropertyLeasePayment(
      id: json['id'].toString(),
      kind: json['kind']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: Money((json['amount_minor'] as num?)?.toInt() ?? 0, currency),
      dueDate: json['due_date']?.toString() ?? '',
    );
  }
}

class PropertyMoveWorkflow {
  const PropertyMoveWorkflow({
    required this.id,
    required this.phase,
    required this.status,
    required this.scheduledAt,
    required this.checklist,
  });

  final String id;
  final String phase;
  final String status;
  final String scheduledAt;
  final List<Map<String, dynamic>> checklist;

  factory PropertyMoveWorkflow.fromJson(Map<String, dynamic> json) {
    final checklistRaw = json['checklist'];
    return PropertyMoveWorkflow(
      id: json['id'].toString(),
      phase: json['phase']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      checklist: checklistRaw is List
          ? checklistRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [],
    );
  }
}

class PropertyFraudSignals {
  const PropertyFraudSignals({
    required this.signals,
    required this.riskScoreE4,
    required this.advisoryOnly,
    this.mlRiskBand = '',
    this.mlReasoning = '',
  });

  final List<String> signals;
  final int riskScoreE4;
  final bool advisoryOnly;
  final String mlRiskBand;
  final String mlReasoning;

  factory PropertyFraudSignals.fromJson(Map<String, dynamic> json) {
    final raw = json['signals'];
    final ml = json['ml'];
    final mlMap = ml is Map ? Map<String, dynamic>.from(ml) : <String, dynamic>{};
    return PropertyFraudSignals(
      signals: raw is List ? raw.map((e) => e.toString()).toList() : [],
      riskScoreE4: (json['risk_score_e4'] as num?)?.toInt() ?? 0,
      advisoryOnly: json['advisory_only'] != false,
      mlRiskBand: mlMap['risk_band']?.toString() ?? '',
      mlReasoning: mlMap['reasoning']?.toString() ?? '',
    );
  }
}

class PropertyOpsDashboard {
  const PropertyOpsDashboard({
    required this.listingsTotal,
    required this.listingsVerified,
    required this.applicationsTotal,
    required this.leasesActive,
    required this.gmvMinor,
    required this.disputesOpen,
    required this.moderationPending,
  });

  final int listingsTotal;
  final int listingsVerified;
  final int applicationsTotal;
  final int leasesActive;
  final int gmvMinor;
  final int disputesOpen;
  final int moderationPending;

  factory PropertyOpsDashboard.fromJson(Map<String, dynamic> json) {
    return PropertyOpsDashboard(
      listingsTotal: (json['listings_total'] as num?)?.toInt() ?? 0,
      listingsVerified: (json['listings_verified'] as num?)?.toInt() ?? 0,
      applicationsTotal: (json['applications_total'] as num?)?.toInt() ?? 0,
      leasesActive: (json['leases_active'] as num?)?.toInt() ?? 0,
      gmvMinor: (json['gmv_minor'] as num?)?.toInt() ?? 0,
      disputesOpen: (json['disputes_open'] as num?)?.toInt() ?? 0,
      moderationPending: (json['moderation_pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class PropertyModerationReport {
  const PropertyModerationReport({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.reason,
    required this.status,
    required this.notes,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String reason;
  final String status;
  final String notes;

  factory PropertyModerationReport.fromJson(Map<String, dynamic> json) {
    return PropertyModerationReport(
      id: json['id'].toString(),
      listingId: json['listing_id']?.toString() ?? '',
      listingTitle: json['listing_title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class PropertyDispute {
  const PropertyDispute({
    required this.id,
    required this.subjectType,
    required this.reason,
    required this.status,
    required this.resolution,
  });

  final String id;
  final String subjectType;
  final String reason;
  final String status;
  final String resolution;

  factory PropertyDispute.fromJson(Map<String, dynamic> json) {
    return PropertyDispute(
      id: json['id'].toString(),
      subjectType: json['subject_type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? '',
    );
  }
}

class PropertyOpsConsole {
  const PropertyOpsConsole({
    required this.dashboard,
    required this.moderationReports,
    required this.disputes,
    required this.recentAudit,
  });

  final PropertyOpsDashboard dashboard;
  final List<PropertyModerationReport> moderationReports;
  final List<PropertyDispute> disputes;
  final List<PropertyOpsAuditEvent> recentAudit;

  factory PropertyOpsConsole.fromJson(Map<String, dynamic> json) {
    final mod = json['moderation'];
    final reports = mod is Map ? mod['reports'] : null;
    final audit = json['recent_audit'];
    return PropertyOpsConsole(
      dashboard: PropertyOpsDashboard.fromJson(
        Map<String, dynamic>.from(json['dashboard'] as Map? ?? {}),
      ),
      moderationReports: reports is List
          ? reports
              .whereType<Map>()
              .map((e) => PropertyModerationReport.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      disputes: (json['disputes'] as List?)
              ?.whereType<Map>()
              .map((e) => PropertyDispute.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      recentAudit: audit is List
          ? audit
              .whereType<Map>()
              .map((e) => PropertyOpsAuditEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }
}

class PropertyOpsAuditEvent {
  const PropertyOpsAuditEvent({
    required this.action,
    required this.entityType,
    required this.actor,
    required this.createdAt,
  });

  final String action;
  final String entityType;
  final String actor;
  final String createdAt;

  factory PropertyOpsAuditEvent.fromJson(Map<String, dynamic> json) {
    return PropertyOpsAuditEvent(
      action: json['action']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      actor: json['actor']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
