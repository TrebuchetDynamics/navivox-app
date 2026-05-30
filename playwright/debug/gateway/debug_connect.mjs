import { openDebugPage } from '../support/browser.mjs';
import { clickSemanticButtonContaining, setNativeInputValue } from '../support/semantic_actions.mjs';

const { browser, page } = await openDebugPage({
  gotoOptions: { waitUntil: 'load', timeout: 30000 },
  settleMs: 5000,
  enableAccessibility: true,
  accessibilitySettleMs: 4000,
});

// 1. Check default values
console.log('=== Default values ===');
const addrDefault = await page.evaluate(() => {
  const input = document.querySelector('input[aria-label="Gateway address field"]');
  return { value: input?.value, textContent: input?.parentElement?.textContent?.trim().substring(0, 50), outer: input?.closest('flt-semantics')?.textContent?.trim().substring(0, 100) };
});
console.log('Address field:', JSON.stringify(addrDefault));

const portDefault = await page.evaluate(() => {
  const input = document.querySelector('input[aria-label="Gateway port field"]');
  return { value: input?.value, parent: input?.parentElement?.textContent?.trim().substring(0, 50) };
});
console.log('Port field:', JSON.stringify(portDefault));

// 2. Fill fields and try connecting
console.log('\n=== Fill and connect ===');

// Fill address
await setNativeInputValue(page, 'input[aria-label="Gateway address field"]', '127.0.0.1');

// Fill port
await setNativeInputValue(page, 'input[aria-label="Gateway port field"]', '8765');

// Fill token
await setNativeInputValue(page, 'input[aria-label="Pairing token field"]', 'nvbx_test');

// Click connect button
console.log('Clicking Connect and talk...');
const connectClicked = await clickSemanticButtonContaining(page, 'Connect and talk', { cancelable: true });
console.log('Connect click result:', JSON.stringify({ found: connectClicked }));

await page.waitForTimeout(3000);

// Check what's on screen now
const screenAfter = await page.evaluate(() => {
  const all = document.querySelectorAll('flt-semantics');
  const texts = [];
  for (const s of all) {
    const t = s.textContent?.trim();
    if (t && t.length > 0) texts.push(t.substring(0, 80));
  }
  return texts.slice(0, 20);
});
console.log('\nScreen after connect click:');
for (const t of screenAfter) console.log(`  "${t}"`);

// Check for error text
const hasError = await page.evaluate(() => {
  return document.body?.textContent?.includes('Could not connect') || 
         document.body?.textContent?.includes('connection failed');
});
console.log('Has error text:', hasError);

// Try clicking connect a different way - via the enclosing flt-semantics
const btnInfo = await page.evaluate(() => {
  const btns = document.querySelectorAll('flt-semantics[role="button"]');
  const results = [];
  for (const b of btns) {
    results.push({
      text: b.textContent?.trim().substring(0, 50),
      rect: b.getBoundingClientRect(),
    });
  }
  return results;
});
console.log('\nButtons found:');
for (const b of btnInfo) {
  console.log(`  "${b.text}" rect=${b.rect.x},${b.rect.y} ${b.rect.width}x${b.rect.height}`);
}

await browser.close();