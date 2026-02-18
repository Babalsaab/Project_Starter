import { test, expect } from "@playwright/test";

test.describe("Home / Landing Page", () => {
  test("should load the landing page with expected content", async ({ page }) => {
    await page.goto("/");
    // Either lands on the landing page or redirects to dashboard (if authenticated)
    const url = page.url();
    const isLanding = !url.includes("/dashboard");
    if (isLanding) {
      // Landing page should have visible text content
      await expect(page.locator("body")).toBeVisible();
      // Check page title exists
      const title = await page.title();
      expect(title.length).toBeGreaterThan(0);
    }
  });

  test("should have correct meta viewport for responsive design", async ({ page }) => {
    await page.goto("/");
    const viewport = page.locator('meta[name="viewport"]');
    await expect(viewport).toHaveAttribute("content", /width=device-width/);
  });

  test("should return 200 status for home page", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);
  });
});
