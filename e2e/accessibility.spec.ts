import { test, expect } from "@playwright/test";

test.describe("Accessibility — Core Pages", () => {
  const pages = [
    { name: "Home", url: "/" },
    { name: "Sign In", url: "/auth/signin" },
    { name: "Sign Up", url: "/auth/signup" },
    { name: "Orchestrator", url: "/orchestrator" },
    { name: "Agents", url: "/orchestrator/agents" },
  ];

  for (const { name, url } of pages) {
    test(`${name} page should have lang attribute on html`, async ({ page }) => {
      await page.goto(url);
      const lang = await page.locator("html").getAttribute("lang");
      expect(lang).toBeTruthy();
    });

    test(`${name} page should have a title`, async ({ page }) => {
      await page.goto(url);
      const title = await page.title();
      expect(title.length).toBeGreaterThan(0);
    });

    test(`${name} page images should have alt text`, async ({ page }) => {
      await page.goto(url);
      // Wait briefly for content to render
      await page.waitForTimeout(2000);
      const images = page.locator("img");
      const count = await images.count();
      for (let i = 0; i < count; i++) {
        const img = images.nth(i);
        const alt = await img.getAttribute("alt");
        // alt can be "" for decorative images, but attribute must exist
        expect(alt).not.toBeNull();
      }
    });
  }
});

test.describe("Responsive Design", () => {
  test("orchestrator page should be usable on mobile viewport", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const response = await page.goto("/orchestrator");
    expect(response?.status()).toBe(200);
    // No horizontal overflow
    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    const viewportWidth = await page.evaluate(() => window.innerWidth);
    expect(bodyWidth).toBeLessThanOrEqual(viewportWidth + 10); // small tolerance
  });

  test("orchestrator page should work on tablet viewport", async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    const response = await page.goto("/orchestrator");
    expect(response?.status()).toBe(200);
    await expect(page.locator("body")).toBeVisible();
  });
});
