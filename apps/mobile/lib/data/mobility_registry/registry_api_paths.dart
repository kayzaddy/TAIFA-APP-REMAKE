class RegistryApiPaths {
  const RegistryApiPaths._();

  static const applications = 'mobility-registry/applications';

  static String registration(String type) =>
      'mobility-registry/applications/${type == 'transport_company' ? 'fleets' : '${type}s'}';

  static String submit(String applicationId) =>
      'mobility-registry/applications/$applicationId/submit';
}
