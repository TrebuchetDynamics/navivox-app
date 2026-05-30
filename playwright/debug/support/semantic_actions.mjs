export async function clickSemanticButtonContaining(page, text, eventOptions = {}) {
  return page.evaluate(({ text, eventOptions }) => {
    const buttons = document.querySelectorAll('flt-semantics[role="button"]');
    for (const button of buttons) {
      if ((button.textContent || '').includes(text)) {
        button.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, ...eventOptions }));
        button.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, ...eventOptions }));
        button.dispatchEvent(new MouseEvent('click', { bubbles: true, ...eventOptions }));
        return true;
      }
    }
    return false;
  }, { text, eventOptions });
}

export async function setNativeInputValue(page, selector, value) {
  return page.evaluate(({ selector, value }) => {
    const input = document.querySelector(selector);
    if (!input) return false;

    const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value')?.set;
    setter?.call(input, value);
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
    return true;
  }, { selector, value });
}
