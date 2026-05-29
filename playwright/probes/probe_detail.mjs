// Deep-dive: gateway management + profile details
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

// Navigate to gateway management
await page.goto('http://127.0.0.1:8767/#/servers', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(2000);

// Click Manage for Local Gormes
await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Manage Local Gormes')) {
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      b.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return;
    }
  }
});
await page.waitForTimeout(3000);

console.log('=== Gateway Detail ===');
const url = page.url();
console.log('URL:', url);

const textLines = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = (s.textContent || '').trim();
    if (t) {
      for (const line of t.split('\n')) {
        const l = line.trim();
        if (l) texts.add(l.substring(0, 100));
      }
    }
  }
  return Array.from(texts).slice(0, 30);
});
console.log('Texts:');
for (const t of textLines) console.log(`  "${t}"`);

// Now go back and test profile detail via long-press equivalent
// Navigate to profile contacts
await page.goto('http://127.0.0.1:8767/#/chats', { waitUntil: 'load', timeout: 20000 });
await page.waitForTimeout(4000);
await page.evaluate(() => {
  document.querySelector('flt-semantics-placeholder')?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
await page.waitForTimeout(2000);

// Try to trigger the profile detail bottom sheet by long-pressing
// Flutter's onLongPress uses GestureLongPress which translates to pointer events
console.log('\n=== Profile Detail (via long press simulation) ===');
const profileDetail = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  for (const b of btns) {
    if ((b.textContent || '').includes('Support Triage')) {
      // Try long press via long duration pointer events
      const rect = b.getBoundingClientRect();
      b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX: rect.x + 10, clientY: rect.y + 10 }));
      // Simulate long press (hold for a moment)
      b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, clientX: rect.x + 10, clientY: rect.y + 10 }));
      b.dispatchEvent(new MouseEvent('contextmenu', { bubbles: true }));
      return 'long-press simulated';
    }
  }
  return 'not found';
});
console.log('Profile detail trigger:', profileDetail);
await page.waitForTimeout(3000);

const detailText = await page.evaluate(() => {
  const sems = document.querySelectorAll('flt-semantics');
  const texts = new Set();
  for (const s of sems) {
    const t = (s.textContent || '').trim();
    if (t) {
      for (const line of t.split('\n')) {
        const l = line.trim();
        if (l && l.length > 10) texts.add(l.substring(0, 100));
      }
    }
  }
  return Array.from(texts).filter(t => !t.includes('Search') && !t.includes('Navivox')).slice(0, 20);
});
console.log('Detail texts:');
for (const t of detailText) console.log(`  "${t}"`);

await page.screenshot({ path: '/tmp/navivox-gateway-detail.png' });
await browser.close();