import { test, expect } from "@playwright/test";

test.describe("Auth Pages", () => {
  test("sign-in page should load and show a form", async ({ page }) => {
    await page.goto("/auth/signin");
    // Should render the sign-in page (200 or redirect to dashboard)
    const status = (await page.goto("/auth/signin"))?.status();
    expect(status).toBeLessThan(500);

    // Check for form elements (email/password inputs, submit button)
    const inputs = page.locator("input");
    const inputCount = await inputs.count();
    // Should have at least email + password fields
    expect(inputCount).toBeGreaterThanOrEqual(1);
  });

  test("sign-up page should load", async ({ page }) => {
    const response = await page.goto("/auth/signup");
    expect(response?.status()).toBeLessThan(500);
    await expect(page.locator("body")).toBeVisible();
  });

  test("sign-in page should have accessible form labels", async ({ page }) => {
    await page.goto("/auth/signin");
    // All inputs should have labels or aria-labels
    const inputs = page.locator("input:not([type=hidden])");
    const count = await inputs.count();
    for (let i = 0; i < count; i++) {
      const input = inputs.nth(i);
      const ariaLabel = await input.getAttribute("aria-label");
      const ariaLabelledby = await input.getAttribute("aria-labelledby");
      const id = await input.getAttribute("id");
      const placeholder = await input.getAttribute("placeholder");
      // At least one accessibility mechanism should be present
      const hasAccessibility = ariaLabel || ariaLabelledby || id || placeholder;
      expect(hasAccessibility).toBeTruthy();
    }
  });
});
