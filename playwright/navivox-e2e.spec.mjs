// Navivox Full App Playwright E2E — comprehensive + deep interaction tests
// Run: node serve_web.mjs && npx playwright test --config=playwright.config.mjs
import { test, expect } from '@playwright/test';
const APP = 'http://127.0.0.1:8767/';

async function a11y(p) {
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', {bubbles:true})));
  await p.waitForTimeout(2000);
}
async function click(p, t) {
  await p.waitForSelector('flt-semantics[role="button"]', {timeout:8000}).catch(()=>{});
  await p.evaluate((text) => {
    for (const role of ['button','menuitem','checkbox','link']) {
      for (const e of document.querySelectorAll(`flt-semantics[role="${role}"]`)) {
        if (((e.textContent||'')+'|'+(e.getAttribute('aria-label')||'')).includes(text)) {
          e.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));
          e.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
          e.dispatchEvent(new MouseEvent('click',{bubbles:true}));
          return;
        }
      }
    }
  }, t);
  await p.waitForTimeout(1000);
}
/** Long-press a Flutter semantics button for profile detail */
async function longPress(p, matchText) {
  await p.evaluate((text) => {
    const btns = document.querySelectorAll('flt-semantics[role="button"]');
    for (const b of btns) {
      if (((b.textContent||'')+'|'+(b.getAttribute('aria-label')||'')).includes(text)) {
        const r = b.getBoundingClientRect();
        b.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true, clientX:r.x+r.width/2, clientY:r.y+r.height/2}));
        return new Promise(resolve => {
          setTimeout(() => {
            b.dispatchEvent(new PointerEvent('pointerup',{bubbles:true, clientX:r.x+r.width/2, clientY:r.y+r.height/2}));
            resolve(true);
          }, 1200);
        });
      }
    }
    return Promise.resolve(false);
  }, matchText);
  await p.waitForTimeout(1000);
}

// ─── 1. Profile Contacts ─────────────────────────────────────────────

test.describe('1. Profile Contacts', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('1a seeded profiles + count + nav', async ({page}) => {
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Support Triage').first()).toBeVisible();
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await expect(page.getByText('3 profiles').first()).toBeVisible();
    await expect(page.getByText('Navivox').first()).toBeVisible();
  });
  test('1b previews, health, attention', async ({page}) => {
    await expect(page.getByText('Ready to work on mineru').first()).toBeVisible();
    await expect(page.getByText('Waiting for auth').first()).toBeVisible();
    await expect(page.getByText('Voice ready').first()).toBeVisible();
    await expect(page.getByText('auth required').first()).toBeVisible();
    await expect(page.getByText('1 attention item').first()).toBeVisible();
  });
  test('1c UI buttons: search, menu, FAB', async ({page}) => {
    await expect(page.getByText('Search profiles').first()).toBeVisible();
    await expect(page.getByText('Open profile list menu').first()).toBeVisible();
    await expect(page.getByText('Add profile').first()).toBeVisible();
  });
  test('1d server filter chips', async ({page}) => {
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="All"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Local Gormes"]')).toBeVisible();
    await expect(page.locator('flt-semantics[role="checkbox"][aria-label="Office Gormes"]')).toBeVisible();
  });
  test('1e filter click narrows count', async ({page}) => {
    await click(page, 'Office Gormes'); await page.waitForTimeout(1000);
    await expect(page.getByText('Support Triage').first()).toBeVisible();
    await expect(page.getByText('1 profile').first()).toBeVisible();
  });
});

// ─── 2. Profile Detail (Long Press) ─────────────────────────────────

test.describe('2. Profile Detail (Long Press)', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('2a long press Support Triage shows diagnostics', async ({page}) => {
    await longPress(page, 'Support Triage');
    await expect(page.getByText('Profile diagnostics').first()).toBeVisible();
    await expect(page.getByText('Health: auth required').first()).toBeVisible();
    await expect(page.getByText('Display name: Support Triage').first()).toBeVisible();
    await expect(page.getByText('Dismiss').first()).toBeVisible();
  });
  test('2b detail includes identity and channels info', async ({page}) => {
    await longPress(page, 'Support Triage');
    await expect(page.getByText('Identity / system prompt').first()).toBeVisible();
    await expect(page.getByText('Connected channels').first()).toBeVisible();
    await expect(page.getByText('Profile ID: support').first()).toBeVisible();
  });
  test('2c long press Mineru shows detail', async ({page}) => {
    await longPress(page, 'Mineru Builder');
    await expect(page.getByText('Profile diagnostics').first()).toBeVisible();
    await expect(page.getByText('Display name: Mineru Builder').first()).toBeVisible();
  });
  test('2d dismiss bottom sheet by Escape', async ({page}) => {
    await longPress(page, 'Support Triage');
    await page.waitForTimeout(500);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(1000);
    // After dismiss, diagnostics should be gone
    await expect(page.getByText('Profile diagnostics').first()).not.toBeVisible();
  });
});

// ─── 3. Chat + Text Entry ────────────────────────────────────────────

test.describe('3. Chat & Text Entry', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('3a navigate to chat then type and send', async ({page}) => {
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await expect(page.locator('[aria-label="Message Gormes"]')).toBeVisible({timeout:5000});
    
    // Click the composer area to focus
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.waitForTimeout(500);
    
    // Type via keyboard
    await page.keyboard.type('playwright e2e text');
    await page.waitForTimeout(300);
    
    // Send via Enter
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    // Message appears
    await expect(page.getByText('playwright e2e text').first()).toBeVisible();
    // Mock echo response
    await expect(page.getByText('Echo: playwright e2e text').first()).toBeVisible();
  });
  test('3b Mineru chat also accepts text', async ({page}) => {
    await click(page, 'Mineru Builder'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/local/mineru');
    
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.waitForTimeout(500);
    await page.keyboard.type('hello mineru');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    await expect(page.getByText('hello mineru').first()).toBeVisible();
    await expect(page.getByText('Echo: hello mineru').first()).toBeVisible();
  });
  test('3c send multiple messages', async ({page}) => {
    await click(page, 'Voice Agent'); await page.waitForTimeout(2000);
    
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.waitForTimeout(500);
    await page.keyboard.type('first message');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1500);
    
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.waitForTimeout(300);
    await page.keyboard.type('second message');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1500);
    
    await expect(page.getByText('first message').first()).toBeVisible();
    await expect(page.getByText('second message').first()).toBeVisible();
    await expect(page.getByText('Echo: first message').first()).toBeVisible();
    await expect(page.getByText('Echo: second message').first()).toBeVisible();
  });
});

// ─── 4. Menu → Screen Navigation ─────────────────────────────────────

test.describe('4. Menu → Screens', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Open profile list menu'); await page.waitForTimeout(1500);
  });
  test('4a Gateways', async ({page}) => {
    await click(page, 'Manage gateways'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
    await expect(page.getByText('Gateways').first()).toBeVisible({timeout:5000});
  });
  test('4b Profiles', async ({page}) => {
    await click(page, 'Manage profiles'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
    await expect(page.getByText('Profiles').first()).toBeVisible({timeout:5000});
  });
  test('4c Memory', async ({page}) => {
    await click(page, 'Memory'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/memory');
  });
  test('4d Config', async ({page}) => {
    await click(page, 'Config'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/config');
  });
  test('4e Settings', async ({page}) => {
    await click(page, 'Settings'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/settings');
    await expect(page.getByText('Settings').first()).toBeVisible({timeout:5000});
  });
});

// ─── 5. Screen Content ──────────────────────────────────────────────

test.describe('5. Screen Content', () => {
  test('5a Gateways list + register', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Gateways').first()).toBeVisible();
    await expect(page.getByText('Local Gormes').first()).toBeVisible();
    await expect(page.getByText('Office Gormes').first()).toBeVisible();
    await expect(page.getByText('Register gateway').first()).toBeVisible();
  });
  test('5b Agents profiles + details', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('Voice Agent').first()).toBeVisible();
    await expect(page.getByText('Status: online').first()).toBeVisible();
    await expect(page.getByText('Refresh profiles').first()).toBeVisible();
    await expect(page.getByText('Active profile').first()).toBeVisible();
  });
  test('5c Memory degraded', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Memory').first()).toBeVisible();
    await expect(page.getByText('Gormes memory API is unavailable.').first()).toBeVisible();
  });
  test('5d Config scope + unavailable', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Config').first()).toBeVisible();
    await expect(page.getByText('Local Gormes').first()).toBeVisible();
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
    await expect(page.getByText('No config available').first()).toBeVisible();
  });
  test('5e Settings sections + command word + overview', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await expect(page.getByText('Voice settings').first()).toBeVisible();
    await expect(page.getByText('Global app settings').first()).toBeVisible();
    await expect(page.getByText('navi').first()).toBeVisible();
    await expect(page.getByText('2 Gormes gateways').first()).toBeVisible();
    await expect(page.getByText('3 profile contacts').first()).toBeVisible();
  });
});

// ─── 6. Settings Lines → Navigation ─────────────────────────────────

test.describe('6. Settings Lines → Navigation', () => {
  test('6a manage gateways → /servers', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage gateways'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
  test('6b manage profiles → /agents', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Manage profile contacts'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
  });
  test('6c active gateway → /servers', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Active Gormes gateway'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
  test('6d active profile → /agents', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Active profile contact'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/agents');
  });
});

// ─── 7. FAB Bottom Sheet ─────────────────────────────────────────────

test.describe('7. FAB Bottom Sheet', () => {
  test.beforeEach(async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
  });
  test('7a FAB opens sheet with options', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(2000);
    await expect(page.getByText('Create from seed').first()).toBeVisible();
    await expect(page.getByText('New profile').first()).toBeVisible();
    await expect(page.getByText('Add server').first()).toBeVisible();
  });
  test('7b Add server navigates to /servers', async ({page}) => {
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await click(page, 'Add server'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/servers');
  });
});

// ─── 8. Back Navigation ──────────────────────────────────────────────

test.describe('8. Back Navigation', () => {
  test('8a chat → back → profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(2000);
    expect(page.url()).toContain('/chats/office/support');
    await page.goBack(); await page.waitForTimeout(2000); await a11y(page);
    expect(page.url()).toContain('/chats');
    await expect(page.getByText('Mineru Builder').first()).toBeVisible();
  });
});

// ─── 9. Screenshots ─────────────────────────────────────────────────

test.describe('9. Screenshots', () => {
  test('9a profiles', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/profiles.png', fullPage:true});
  });
  test('9b chat with message', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Support Triage'); await page.waitForTimeout(1500);
    await page.locator('[aria-label="Message Gormes"]').first().click({force:true});
    await page.keyboard.type('e2e message'); await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await page.screenshot({path:'playwright/screenshots/chat.png', fullPage:true});
  });
  test('9c servers', async ({page}) => {
    await page.goto(APP+'#/servers', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/servers.png', fullPage:true});
  });
  test('9d agents', async ({page}) => {
    await page.goto(APP+'#/agents', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/agents.png', fullPage:true});
  });
  test('9e memory', async ({page}) => {
    await page.goto(APP+'#/memory', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/memory.png', fullPage:true});
  });
  test('9f config', async ({page}) => {
    await page.goto(APP+'#/config', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/config.png', fullPage:true});
  });
  test('9g settings', async ({page}) => {
    await page.goto(APP+'#/settings', {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await page.screenshot({path:'playwright/screenshots/settings.png', fullPage:true});
  });
  test('9h profile detail sheet', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await longPress(page, 'Support Triage'); await page.waitForTimeout(500);
    await page.screenshot({path:'playwright/screenshots/profile-detail.png', fullPage:true});
    await page.keyboard.press('Escape');
  });
  test('9i FAB bottom sheet', async ({page}) => {
    await page.goto(APP, {timeout:15000}); await page.waitForTimeout(2000); await a11y(page);
    await click(page, 'Add profile'); await page.waitForTimeout(1500);
    await page.screenshot({path:'playwright/screenshots/fab-sheet.png', fullPage:true});
  });
});