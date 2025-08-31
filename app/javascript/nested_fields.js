// app/javascript/nested_fields.js
document.addEventListener('turbo:load', () => {
  const ingContainer = document.getElementById('ingredients-container');
  const stepContainer = document.getElementById('steps-container');
  const addIngBtn = document.getElementById('add-ingredient');
  const addStepBtn = document.getElementById('add-step');
  const ingTpl = document.getElementById('ingredient-template');
  const stepTpl = document.getElementById('step-template');

  if (!ingContainer || !stepContainer) return;

  // 既存行数から連番スタート（idの衝突防止 & 並び番号用）
  let ingIndex = ingContainer.querySelectorAll('.ingredient-field').length || 0;
  let stepIndex = stepContainer.querySelectorAll('.step-field').length || 0;

  const addFromTemplate = (tplEl, container, kind) => {
    const index = (kind === 'ingredient') ? ingIndex : stepIndex;
    // NEW_RECORD を連番に置換して挿入
    const html = tplEl.innerHTML.replaceAll('NEW_RECORD', index);
    const wrapper = document.createElement('div');
    wrapper.innerHTML = html.trim();
    const node = wrapper.firstElementChild;
    container.appendChild(node);

    // 並び番号の自動付番
    if (kind === 'ingredient') {
      const orderInput = node.querySelector('input[name*="[order_number]"]');
      if (orderInput) orderInput.value = index + 1;
      ingIndex += 1;
    } else {
      const stepInput = node.querySelector('input[name*="[step_number]"]');
      if (stepInput) stepInput.value = index + 1;
      stepIndex += 1;
    }
  };

  if (addIngBtn && ingTpl) {
    addIngBtn.addEventListener('click', () => addFromTemplate(ingTpl, ingContainer, 'ingredient'));
  }
  if (addStepBtn && stepTpl) {
    addStepBtn.addEventListener('click', () => addFromTemplate(stepTpl, stepContainer, 'step'));
  }

  // 削除（イベントデリゲーション）
  document.addEventListener('click', (e) => {
    const ingBtn = e.target.closest('.remove-ingredient');
    if (ingBtn) {
      const field = ingBtn.closest('.ingredient-field');
      if (field) field.remove(); // new画面はDOMから消せばOK
      e.preventDefault();
    }
    const stepBtn = e.target.closest('.remove-step');
    if (stepBtn) {
      const field = stepBtn.closest('.step-field');
      if (field) field.remove();
      e.preventDefault();
    }
  });
});
