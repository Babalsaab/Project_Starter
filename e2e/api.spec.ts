import { test, expect } from "@playwright/test";

test.describe("API Routes — Orchestrator", () => {
  test("GET /api/orchestrator/sessions should return JSON", async ({ request }) => {
    const response = await request.get("/api/orchestrator/sessions");
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json).toHaveProperty("sessions");
    expect(Array.isArray(json.sessions)).toBe(true);
  });

  test("GET /api/orchestrator/agents should return agent registry", async ({ request }) => {
    const response = await request.get("/api/orchestrator/agents");
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json).toHaveProperty("total");
    expect(json.total).toBeGreaterThanOrEqual(60); // We have 66+ agents
    expect(json).toHaveProperty("chiefs");
    expect(json).toHaveProperty("tech");
    expect(json).toHaveProperty("marketing");
    expect(Array.isArray(json.chiefs)).toBe(true);
    expect(Array.isArray(json.tech)).toBe(true);
    expect(Array.isArray(json.marketing)).toBe(true);
  });

  test("GET /api/orchestrator/agents should include personas", async ({ request }) => {
    const response = await request.get("/api/orchestrator/agents");
    const json = await response.json();
    expect(json).toHaveProperty("personas");
    expect(Array.isArray(json.personas)).toBe(true);
    expect(json.personas.length).toBeGreaterThanOrEqual(40);
  });
});

test.describe("Error Handling", () => {
  test("404 page should render for unknown routes", async ({ page }) => {
    const response = await page.goto("/this-route-does-not-exist-12345");
    // Next.js returns 404
    expect(response?.status()).toBe(404);
  });

  test("non-existent API route should return 404 or 405", async ({ request }) => {
    const response = await request.get("/api/orchestrator/nonexistent");
    expect([404, 405]).toContain(response.status());
  });
});

test.describe("Performance Basics", () => {
  test("home page should load within 5 seconds", async ({ page }) => {
    const start = Date.now();
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const elapsed = Date.now() - start;
    expect(elapsed).toBeLessThan(5000);
  });

  test("API response should be fast (< 2s)", async ({ request }) => {
    const start = Date.now();
    await request.get("/api/orchestrator/agents");
    const elapsed = Date.now() - start;
    expect(elapsed).toBeLessThan(2000);
  });
});
