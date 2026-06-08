// Confirmacao de exclusao para formularios de deleção
document.querySelectorAll('form[data-confirm]').forEach(function(form) {
  form.addEventListener('submit', function(e) {
    if (!confirm(form.dataset.confirm)) e.preventDefault();
  });
});

// Calculo automatico do total no formulario de pedido
var selProduto = document.getElementById('sel-produto');
var inpQtd     = document.getElementById('inp-qtd');

function calcularTotal() {
  if (!selProduto || !inpQtd) return;
  var opcao = selProduto.options[selProduto.selectedIndex];
  var preco = parseFloat(opcao.dataset.preco || 0);
  var qtd   = parseInt(inpQtd.value || 1);
  var total = (preco * qtd).toFixed(2).replace('.', ',');
  var el    = document.getElementById('preview-total');
  if (el) el.textContent = 'Total estimado: R$ ' + total;
}

if (selProduto) selProduto.addEventListener('change', calcularTotal);
if (inpQtd)     inpQtd.addEventListener('input', calcularTotal);
