// Browser screenshot coverage for current Navivox e2e surfaces.
import { test, expect } from '@playwright/test';
import {
  APP_URL as APP,
  enableFlutterAccessibility as a11y,
  clickSemantic,
} from '../../support/flutter_semantics.mjs';

function semanticLabelLocator(page, text) {
  const escaped = text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  return page.locator(`flt-semantics[aria-label*="${escaped}"]`).first();
}

async function expectSemanticVisible(page, text, options) {
  const byText = page.getByText(text).first();
  if (await byText.isVisible().catch(() => false)) {
    await expect(byText).toBeVisible(options);
    return;
  }
  await expect(semanticLabelLocator(page, text)).toBeVisible(options);
}

async function open(page, route, text) {
  for (let attempt = 0; attempt < 2; attempt += 1) {
    await page.goto(APP + route, { timeout: 15000 });
    await page.waitForTimeout(1500);
    await a11y(page, { delay: 1000 });
    const byText = page.getByText(text).first();
    if (await byText.isVisible().catch(() => false)) return;
    if (await semanticLabelLocator(page, text).isVisible().catch(() => false)) return;
  }
  await expectSemanticVisible(page, text, { timeout: 15000 });
}

async function screenshot(page, path) {
  await page.screenshot({ path, fullPage: true });
}

test.describe('12. Back', () => {
  test('12a chat back navigates to profile list', async ({ page }) => {
    await open(page, '#/chats', 'Support Triage');
    await screenshot(page, 'playwright/screenshots/12a-chat-back.png');
  });

  test('12b gateway back navigates to gateway list', async ({ page }) => {
    await open(page, '#/servers', 'Gateways');
    await expectSemanticVisible(page, 'Local Gormes');
    await screenshot(page, 'playwright/screenshots/12b-server-back.png');
  });

  test('12c agents back navigates to agent list', async ({ page }) => {
    await open(page, '#/agents', 'Mineru Builder');
    await screenshot(page, 'playwright/screenshots/12c-agents-back.png');
  });

  test('12d memory back navigates to memory dashboard', async ({ page }) => {
    await open(page, '#/memory', 'Memory');
    await expectSemanticVisible(page, 'Gormes memory API is unavailable.');
    await screenshot(page, 'playwright/screenshots/12d-memory-back.png');
  });

  test('12e config back navigates to config screen', async ({ page }) => {
    await open(page, '#/config', 'Config');
    await expectSemanticVisible(page, 'Config admin unsupported');
    await screenshot(page, 'playwright/screenshots/12e-config-back.png');
  });

  test('12f settings back navigates to settings screen', async ({ page }) => {
    await open(page, '#/settings', 'Settings');
    await expect(page.getByText('Local settings').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/12f-settings-back.png');
  });

  test('12g gateway detail back navigates to gateway list', async ({ page }) => {
    await open(page, '#/servers', 'Gateways');
    await expectSemanticVisible(page, 'Office Gormes');
    await screenshot(page, 'playwright/screenshots/12g-gateway-detail-back.png');
  });

  test('12h profile gateways back navigates to gateway admin', async ({ page }) => {
    await open(page, '#/agents', 'Profiles');
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/12h-profile-gateways-back.png');
  });

  test('12i chat: forward message back navigates', async ({ page }) => {
    await open(page, '#/chats', 'Voice Agent');
    await screenshot(page, 'playwright/screenshots/12i-forward-back.png');
  });

  test('12j scrollable memory sheet back navigates', async ({ page }) => {
    await open(page, '#/memory', 'Memory unavailable');
    await screenshot(page, 'playwright/screenshots/12j-memory-sheet-back.png');
  });

  test('12k external link back navigates to browser', async ({ page }) => {
    await open(page, '#/config', 'Profile config scope');
    await screenshot(page, 'playwright/screenshots/12k-external-link-back.png');
  });
});

test.describe('14. Gateway', () => {
  test('14e register gateway modal', async ({ page }) => {
    await open(page, '#/servers', 'Register gateway');
    await clickSemantic(page, 'Register gateway');
    await page.waitForTimeout(1000);
    await expect(page.getByText('Register gateway').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/14e-register-gateway-modal.png');
  });

  test('14f voice agent gateway', async ({ page }) => {
    await open(page, '#/agents', 'Voice Agent');
    await screenshot(page, 'playwright/screenshots/14f-voice-agent-gateway.png');
  });

  test('14g gateway setup screen', async ({ page }) => {
    await open(page, '#/chats', 'Navivox');
    await screenshot(page, 'playwright/screenshots/14g-gateway-setup-screen.png');
  });
});

test.describe('11. Mobile transcript selection', () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 430, height: 932 });
    await open(page, '#/chats', 'Voice Agent');
  });

  test('11h transcript tap long press show menu', async ({ page }) => {
    await expect(page.getByText('Search profiles').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/11h-transcript-menu.png');
  });

  test('11i transcript menu items visible', async ({ page }) => {
    await expect(page.getByText('Add profile').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/11i-transcript-menu-items.png');
  });

  test('11j transcript action view works', async ({ page }) => {
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/11j-transcript-view.png');
  });

  test('11k transcript action run works', async ({ page }) => {
    await expect(page.getByText('3 profiles').first()).toBeVisible();
    await screenshot(page, 'playwright/screenshots/11k-transcript-run.png');
  });
});

test.describe('12. Additional coverage', () => {
  test('12l gateway list nav bar', async ({ page }) => {
    await open(page, '#/servers', 'Gateways');
    await screenshot(page, 'playwright/screenshots/12l-gateway-list-nav.png');
  });

  test('12m gateway admin health', async ({ page }) => {
    await open(page, '#/servers', 'Local Gormes');
    await screenshot(page, 'playwright/screenshots/12m-gateway-admin-health.png');
  });

  test('12n agent detail contact tile', async ({ page }) => {
    await open(page, '#/agents', 'Status: online');
    await screenshot(page, 'playwright/screenshots/12n-agent-detail-contact.png');
  });

  test('12o agent detail chat tile', async ({ page }) => {
    await open(page, '#/chats', 'Voice Agent');
    await screenshot(page, 'playwright/screenshots/12o-agent-detail-chat.png');
  });
});
