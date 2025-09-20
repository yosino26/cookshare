// CookShare 管理画面用JavaScript
document.addEventListener('DOMContentLoaded', function() {
  
  // ========================================
  // 共通機能
  // ========================================
  
  // ローディング表示/非表示
  window.showLoading = function() {
    const spinner = document.getElementById('loadingSpinner');
    if (spinner) {
      spinner.style.display = 'block';
    }
  };
  
  window.hideLoading = function() {
    const spinner = document.getElementById('loadingSpinner');
    if (spinner) {
      spinner.style.display = 'none';
    }
  };
  
  // トーストメッセージ表示
  window.showToast = function(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0 position-fixed`;
    toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999;';
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;
    
    document.body.appendChild(toast);
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
    
    // 自動削除
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 5000);
  };
  
  // ========================================
  // フォーム関連
  // ========================================
  
  // 自動検索（Enter キー）
  document.querySelectorAll('input[type="search"], input[name="search"]').forEach(input => {
    input.addEventListener('keyup', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        this.closest('form').submit();
      }
    });
  });
  
  // フィルター変更時の自動検索（オプション）
  document.querySelectorAll('.auto-submit').forEach(select => {
    select.addEventListener('change', function() {
      this.closest('form').submit();
    });
  });
  
  // フォーム確認メッセージ
  document.querySelectorAll('[data-confirm]').forEach(element => {
    element.addEventListener('click', function(e) {
      const message = this.getAttribute('data-confirm');
      if (!confirm(message)) {
        e.preventDefault();
        return false;
      }
    });
  });
  
  // ========================================
  // 一括操作機能
  // ========================================
  
  // 汎用的な一括操作処理
  function initBulkActions(config) {
    const {
      selectAllId,
      checkboxClass,
      bulkButtonId,
      bulkFormId,
      cancelButtonId,
      bulkFormSelector
    } = config;
    
    const selectAll = document.getElementById(selectAllId);
    const checkboxes = document.querySelectorAll(`.${checkboxClass}`);
    const bulkButton = document.getElementById(bulkButtonId);
    const bulkForm = document.getElementById(bulkFormId);
    const cancelButton = document.getElementById(cancelButtonId);
    
    if (!selectAll || !checkboxes.length || !bulkButton) return;
    
    // 全選択/全解除
    selectAll.addEventListener('change', function() {
      checkboxes.forEach(checkbox => {
        checkbox.checked = this.checked;
      });
      updateBulkButton();
    });
    
    // 個別チェックボックス
    checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', function() {
        updateBulkButton();
        updateSelectAllState();
      });
    });
    
    // 一括操作ボタン更新
    function updateBulkButton() {
      const checkedCount = document.querySelectorAll(`.${checkboxClass}:checked`).length;
      bulkButton.disabled = checkedCount === 0;
      bulkButton.textContent = checkedCount > 0 ? 
        `一括操作 (${checkedCount}件)` : '一括操作';
    }
    
    // 全選択チェックボックス状態更新
    function updateSelectAllState() {
      const checkedCount = document.querySelectorAll(`.${checkboxClass}:checked`).length;
      const totalCount = checkboxes.length;
      
      selectAll.checked = checkedCount === totalCount;
      selectAll.indeterminate = checkedCount > 0 && checkedCount < totalCount;
    }
    
    // 一括操作フォーム表示/非表示
    bulkButton.addEventListener('click', function() {
      if (!this.disabled && bulkForm) {
        const isVisible = bulkForm.style.display !== 'none';
        bulkForm.style.display = isVisible ? 'none' : 'block';
      }
    });
    
    // キャンセルボタン
    if (cancelButton && bulkForm) {
      cancelButton.addEventListener('click', function() {
        bulkForm.style.display = 'none';
      });
    }
    
    // 一括操作フォーム送信処理
    const form = document.querySelector(bulkFormSelector);
    if (form) {
      form.addEventListener('submit', function(e) {
        const checkedBoxes = document.querySelectorAll(`.${checkboxClass}:checked`);
        if (checkedBoxes.length === 0) {
          e.preventDefault();
          alert('操作対象を選択してください。');
          return false;
        }
        
        // 既存のhidden inputを削除
        this.querySelectorAll('input[type="hidden"][name*="_ids[]"]').forEach(input => {
          input.remove();
        });
        
        // 選択されたIDをhidden inputとして追加
        const inputName = checkboxClass.replace('-checkbox', '') + '_ids[]';
        checkedBoxes.forEach(checkbox => {
          const hiddenInput = document.createElement('input');
          hiddenInput.type = 'hidden';
          hiddenInput.name = inputName;
          hiddenInput.value = checkbox.value;
          this.appendChild(hiddenInput);
        });
        
        // 確認メッセージ
        const action = this.querySelector('select[name="bulk_action"]').value;
        const actionText = this.querySelector(`option[value="${action}"]`).textContent;
        if (!confirm(`選択した${checkedBoxes.length}件を${actionText}しますか？`)) {
          e.preventDefault();
          return false;
        }
      });
    }
  }
  
  // レポート一括操作
  initBulkActions({
    selectAllId: 'selectAllReports',
    checkboxClass: 'report-checkbox',
    bulkButtonId: 'bulkActionBtn',
    bulkFormId: 'bulkActionForm',
    cancelButtonId: 'cancelBulk',
    bulkFormSelector: '#bulk-form'
  });
  
  // コメント一括操作
  initBulkActions({
    selectAllId: 'selectAllComments',
    checkboxClass: 'comment-checkbox',
    bulkButtonId: 'bulkActionBtn',
    bulkFormId: 'bulkActionForm',
    cancelButtonId: 'cancelBulk',
    bulkFormSelector: '#bulk-form'
  });
  
  // ========================================
  // UI改善機能
  // ========================================
  
  // ツールチップ初期化
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltips.forEach(tooltip => {
    new bootstrap.Tooltip(tooltip);
  });
  
  // ポップオーバー初期化
  const popovers = document.querySelectorAll('[data-bs-toggle="popover"]');
  popovers.forEach(popover => {
    new bootstrap.Popover(popover);
  });
  
  // テーブル行クリックで詳細ページへ（オプション）
  document.querySelectorAll('.clickable-row').forEach(row => {
    row.addEventListener('click', function(e) {
      // チェックボックスやボタンがクリックされた場合は除外
      if (e.target.type === 'checkbox' || 
          e.target.tagName === 'BUTTON' || 
          e.target.tagName === 'A') {
        return;
      }
      
      const url = this.getAttribute('data-url');
      if (url) {
        window.location.href = url;
      }
    });
    
    // ホバー効果
    row.style.cursor = 'pointer';
  });
});

// ========================================
// エクスポート関数
// ========================================

// CSVエクスポートの進捗表示
window.trackExport = function(url, filename) {
  showLoading();
  
  fetch(url)
    .then(response => response.blob())
    .then(blob => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
      
      showToast('エクスポートが完了しました。', 'success');
    })
    .catch(error => {
      console.error('Export error:', error);
      showToast('エクスポートに失敗しました。', 'danger');
    })
    .finally(() => {
      hideLoading();
    });
};