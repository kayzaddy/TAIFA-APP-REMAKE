# Taifa Platform JavaScript / TypeScript SDK (ESM)

/**
 * Thin REST client. Does not reimplement payments or identity.
 * @param {string} baseUrl
 * @param {string} bearerToken
 */
export function createTaifaClient(baseUrl, bearerToken) {
  const root = baseUrl.replace(/\/$/, "");

  async function request(method, path, body) {
    const res = await fetch(`${root}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${bearerToken}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    const data = text ? JSON.parse(text) : {};
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${text}`);
    }
    return data;
  }

  return {
    ecosystemBlueprint: () => request("GET", "/api/v1/ecosystem/blueprint"),
    myModules: () => request("GET", "/api/v1/ecosystem/modules"),
    enableModule: (moduleCode, enabled = true) =>
      request("POST", `/api/v1/ecosystem/modules/${moduleCode}/enable`, {
        enabled,
      }),
    invokeAi: (capability, payload = {}) =>
      request("POST", `/api/v1/ecosystem/ai/${capability}/invoke`, {
        payload,
      }),
    wallet: () => request("GET", "/api/v1/payments/wallet"),
    openCatalog: () => request("GET", "/api/v1/ecosystem/open/catalog"),
  };
}
