/**
 * =============================================================================
 * Lighthouse Configuration for CTO Evaluation Suite
 * =============================================================================
 * Custom configuration for web performance evaluation.
 * =============================================================================
 */

module.exports = {
  extends: 'lighthouse:default',

  settings: {
    // Run in desktop mode by default
    formFactor: 'desktop',
    screenEmulation: {
      mobile: false,
      width: 1350,
      height: 940,
      deviceScaleFactor: 1,
      disabled: false,
    },

    // Throttling settings (simulate average conditions)
    throttling: {
      rttMs: 40,
      throughputKbps: 10240,
      cpuSlowdownMultiplier: 1,
    },

    // Only run specific categories
    onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],

    // Skip specific audits that may not apply
    skipAudits: [
      'uses-http2', // May not apply to local testing
      'redirects-http', // May not apply to local testing
    ],
  },

  // Custom pass configuration
  passes: [
    {
      passName: 'defaultPass',
      recordTrace: true,
      useThrottling: true,
      pauseAfterFcpMs: 1000,
      pauseAfterLoadMs: 1000,
      networkQuietThresholdMs: 1000,
      cpuQuietThresholdMs: 1000,
      gatherers: [],
    },
  ],

  // Categories configuration
  categories: {
    performance: {
      title: 'Performance',
      description: 'Performance metrics and optimization opportunities',
      auditRefs: [
        { id: 'first-contentful-paint', weight: 10 },
        { id: 'largest-contentful-paint', weight: 25 },
        { id: 'total-blocking-time', weight: 30 },
        { id: 'cumulative-layout-shift', weight: 25 },
        { id: 'speed-index', weight: 10 },
      ],
    },
  },
};
