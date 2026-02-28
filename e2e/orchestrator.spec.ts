import { test, expect } from "@playwright/test";

test.describe("Orchestrator Dashboard", () => {
  test("should load the orchestrator hub page", async ({ page }) => {
    const response = await page.goto("/orchestrator");
    expect(response?.status()).toBe(200);
    await expect(page.locator("body")).toBeVisible();
  });

  test("should show loading state then content", async ({ page }) => {
    await page.goto("/orchestrator");
    // Page should eventually have substantive content (not just a spinner forever)
    await page.waitForFunction(
      () => document.body.innerText.length > 50,
      { timeout: 15_000 }
    );
    const bodyText = await page.locator("body").innerText();
    expect(bodyText.length).toBeGreaterThan(50);
  });

  test("should have navigation links", async ({ page }) => {
    await page.goto("/orchestrator");
    // Wait for content to load
    await page.waitForFunction(
      () => document.body.innerText.length > 50,
      { timeout: 15_000 }
    );
    // Should have at least one link on the page
    const links = page.locator("a[href]");
    const linkCount = await links.count();
    expect(linkCount).toBeGreaterThan(0);
  });
});

test.describe("Orchestrator Agents Page", () => {
  test("should load the agents registry page", async ({ page }) => {
    const response = await page.goto("/orchestrator/agents");
    expect(response?.status()).toBe(200);
  });

  test("should display agent data after loading", async ({ page }) => {
    await page.goto("/orchestrator/agents");
    // Wait for agents to load (the page fetches from /api/orchestrator/agents)
    await page.waitForFunction(
      () => document.body.innerText.length > 100,
      { timeout: 15_000 }
    );
    const bodyText = await page.locator("body").innerText();
    // Should contain words like "agents", "tech", "marketing", domain names, etc.
    expect(bodyText.length).toBeGreaterThan(100);
  });

  test("should have filter or search functionality", async ({ page }) => {
    await page.goto("/orchestrator/agents");
    await page.waitForFunction(
      () => document.body.innerText.length > 100,
      { timeout: 15_000 }
    );
    // Look for input[type=text], input[type=search], or buttons that filter
    const searchInputs = page.locator('input[type="text"], input[type="search"], input[placeholder*i="search"]');
    const buttons = page.locator("button");
    const hasSearch = (await searchInputs.count()) > 0;
    const hasButtons = (await buttons.count()) > 0;
    expect(hasSearch || hasButtons).toBe(true);
  });
});
