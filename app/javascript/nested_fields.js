// 2重初期化ガード（どこかで再importされても安心）
if (window.__nestedFieldsInitialized) {
  // 既に有効なら何もしない
} else {
  window.__nestedFieldsInitialized = true;

  document.addEventListener('turbo:load', () => {
    const ingContainer = document.getElementById('ingredients-container');
    const stepContainer = document.getElementById('steps-container');
    const addIngBtn = document.getElementById('add-ingredient');
    const addStepBtn = document.getElementById('add-step');
    const ingTpl = document.getElementById('ingredient-template');
    const stepTpl = document.getElementById('step-template');

    if (!ingContainer || !stepContainer) return;

    // 既存行数から採番開始
    let ingIndex = ingContainer.querySelectorAll('.ingredient-field').length || 0;
    let stepIndex = stepContainer.querySelectorAll('.step-field').length || 0;

    const addFromTemplate = (tplEl, container, kind) => {
      const index = (kind === 'ingredient') ? ingIndex : stepIndex;
      const html = tplEl.innerHTML.replaceAll('NEW_RECORD', index);
      const wrapper = document.createElement('div');
      wrapper.innerHTML = html.trim();
      const node = wrapper.firstElementChild;
      container.appendChild(node);

      // 並び番号を自動セット
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

    // 同一ボタンへの二重バインド防止（data-bound）
    if (addIngBtn && ingTpl && !addIngBtn.dataset.bound) {
      addIngBtn.addEventListener('click', () => addFromTemplate(ingTpl, ingContainer, 'ingredient'));
      addIngBtn.dataset.bound = 'true';
    }
    if (addStepBtn && stepTpl && !addStepBtn.dataset.bound) {
      addStepBtn.addEventListener('click', () => addFromTemplate(stepTpl, stepContainer, 'step'));
      addStepBtn.dataset.bound = 'true';
    }

    // 削除の委譲ハンドラは1回だけ
    if (!window.__nestedFieldsDeleteBound) {
      document.addEventListener('click', (e) => {
        // 材料
        const ingBtn = e.target.closest('.remove-ingredient');
        if (ingBtn) {
          const field = ingBtn.closest('.ingredient-field');
          if (field) {
            const destroyInput = field.querySelector('input[name*="[_destroy]"]');
            if (destroyInput) { destroyInput.value = '1'; field.style.display = 'none'; } // edit 既存
            else { field.remove(); } // new 追加分
          }
          e.preventDefault();
        }
        // 手順
        const stepBtn = e.target.closest('.remove-step');
        if (stepBtn) {
          const field = stepBtn.closest('.step-field');
          if (field) {
            const destroyInput = field.querySelector('input[name*="[_destroy]"]');
            if (destroyInput) { destroyInput.value = '1'; field.style.display = 'none'; }
            else { field.remove(); }
          }
          e.preventDefault();
        }
      });
      window.__nestedFieldsDeleteBound = true;
    }
  });
}

