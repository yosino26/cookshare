document.addEventListener('DOMContentLoaded', function() {
  // 材料追加ボタンのイベント
  const addIngredientBtn = document.getElementById('add-ingredient');
  if (addIngredientBtn) {
    addIngredientBtn.addEventListener('click', function(e) {
      e.preventDefault();
      addIngredientField();
    });
  }

  // 手順追加ボタンのイベント  
  const addStepBtn = document.getElementById('add-step');
  if (addStepBtn) {
    addStepBtn.addEventListener('click', function(e) {
      e.preventDefault();
      addStepField();
    });
  }

  // 削除ボタンのイベント（既存の要素にも対応）
  document.addEventListener('click', function(e) {
    if (e.target.classList.contains('remove-ingredient')) {
      e.preventDefault();
      removeField(e.target, 'ingredient');
    }
    
    if (e.target.classList.contains('remove-step')) {
      e.preventDefault();
      removeField(e.target, 'step');
    }
  });
});

function addIngredientField() {
  const container = document.getElementById('ingredients-container');
  const index = container.children.length;
  
  const html = `
    <div class="ingredient-field mb-3">
      <div class="row align-items-end">
        <div class="col-md-6">
          <label class="form-label">材料名</label>
          <input type="text" name="recipe[ingredients_attributes][${index}][name]" class="form-control" placeholder="例: トマト">
        </div>
        <div class="col-md-4">
          <label class="form-label">分量</label>
          <input type="text" name="recipe[ingredients_attributes][${index}][amount]" class="form-control" placeholder="例: 2個">
          <input type="hidden" name="recipe[ingredients_attributes][${index}][order_number]" value="${index + 1}">
        </div>
        <div class="col-md-2">
          <button type="button" class="btn btn-outline-danger remove-ingredient">削除</button>
        </div>
      </div>
    </div>
  `;
  
  container.insertAdjacentHTML('beforeend', html);
}

function addStepField() {
  const container = document.getElementById('steps-container');
  const index = container.children.length;
  
  const html = `
    <div class="step-field mb-3">
      <div class="row align-items-end">
        <div class="col-md-10">
          <label class="form-label">手順 ${index + 1}</label>
          <textarea name="recipe[steps_attributes][${index}][instruction]" class="form-control" rows="3" placeholder="手順を詳しく説明してください"></textarea>
          <input type="hidden" name="recipe[steps_attributes][${index}][step_number]" value="${index + 1}">
        </div>
        <div class="col-md-2">
          <button type="button" class="btn btn-outline-danger remove-step">削除</button>
        </div>
      </div>
    </div>
  `;
  
  container.insertAdjacentHTML('beforeend', html);
}

function removeField(button, type) {
  const field = button.closest(`.${type}-field`);
  
  // 既存のレコードの場合は、_destroyフィールドを追加
  const idInput = field.querySelector('input[name*="[id]"]');
  if (idInput) {
    const destroyInput = document.createElement('input');
    destroyInput.type = 'hidden';
    destroyInput.name = idInput.name.replace('[id]', '[_destroy]');
    destroyInput.value = '1';
    field.appendChild(destroyInput);
    field.style.display = 'none';
  } else {
    // 新しく追加されたフィールドは完全に削除
    field.remove();
  }
  
  // 手順の場合、番号を振り直し
  if (type === 'step') {
    renumberSteps();
  }
}

function renumberSteps() {
  const steps = document.querySelectorAll('.step-field:not([style*="display: none"])');
  steps.forEach((step, index) => {
    const label = step.querySelector('label');
    if (label) {
      label.textContent = `手順 ${index + 1}`;
    }
    
    const numberInput = step.querySelector('input[name*="[step_number]"]');
    if (numberInput) {
      numberInput.value = index + 1;
    }
  });
}