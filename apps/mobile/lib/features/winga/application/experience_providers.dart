import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/opportunity_models.dart';

class ExperiencePrefs {
  const ExperiencePrefs({
    this.onboardingComplete = false,
    this.savedOpportunityIds = const {},
    this.appliedOpportunityIds = const {},
  });

  final bool onboardingComplete;
  final Set<String> savedOpportunityIds;
  final Set<String> appliedOpportunityIds;

  ExperiencePrefs copyWith({
    bool? onboardingComplete,
    Set<String>? savedOpportunityIds,
    Set<String>? appliedOpportunityIds,
  }) {
    return ExperiencePrefs(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      savedOpportunityIds: savedOpportunityIds ?? this.savedOpportunityIds,
      appliedOpportunityIds:
          appliedOpportunityIds ?? this.appliedOpportunityIds,
    );
  }
}

class ExperiencePrefsNotifier extends Notifier<ExperiencePrefs> {
  @override
  ExperiencePrefs build() => const ExperiencePrefs();

  void completeOnboarding() =>
      state = state.copyWith(onboardingComplete: true);

  void toggleSave(String id) {
    final next = {...state.savedOpportunityIds};
    if (!next.add(id)) next.remove(id);
    state = state.copyWith(savedOpportunityIds: next);
  }

  void apply(String id) {
    state = state.copyWith(
      appliedOpportunityIds: {...state.appliedOpportunityIds, id},
    );
  }
}

final experiencePrefsProvider =
    NotifierProvider<ExperiencePrefsNotifier, ExperiencePrefs>(
  ExperiencePrefsNotifier.new,
);

final opportunityFeedProvider = Provider<List<WingaOpportunity>>((ref) {
  return WingaOpportunityCatalog.all();
});
