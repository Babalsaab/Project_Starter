# Lighthouse Configuration

This directory contains Lighthouse configuration for web performance analysis.

## Overview

Lighthouse is used to evaluate frontend performance, accessibility, and best practices for web applications.

## Files

- `lighthouse-config.js` - Custom Lighthouse configuration

## Usage

### Run Lighthouse analysis

```bash
lighthouse https://your-site.com --config-path=tools/lighthouse/lighthouse-config.js
```

### Programmatic usage

```javascript
const lighthouse = require('lighthouse');
const config = require('./lighthouse-config.js');

const result = await lighthouse(url, {}, config);
```

## Metrics Evaluated

- **Performance**
  - First Contentful Paint (FCP)
  - Largest Contentful Paint (LCP)
  - Time to Interactive (TTI)
  - Total Blocking Time (TBT)
  - Cumulative Layout Shift (CLS)

- **Accessibility**
  - Color contrast
  - ARIA attributes
  - Keyboard navigation
  - Screen reader compatibility

- **Best Practices**
  - HTTPS usage
  - Console errors
  - Deprecated APIs

- **SEO**
  - Meta tags
  - Crawlability
  - Mobile friendliness
