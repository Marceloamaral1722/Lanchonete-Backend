document.addEventListener('DOMContentLoaded', () => {
  if (!checarAuth()) return;
  carregarMeusPedidos();
});

async function carregarMeusPedidos() {
  const cont = document.getElementById('lista-pedidos');
  try {
    const resp = await fetch(`${API_URL}/pedidos`, { headers: authHeaders() });
    const pedidos = await resp.json();

    if (!pedidos.length) {
      cont.innerHTML = `
        <div class="empty-state">
          <i class="bi bi-bag-x"></i>
          <p>Você ainda não fez nenhum pedido.</p>
          <a href="cardapio.html" class="btn btn-primary">Ver cardápio</a>
        </div>`;
      return;
    }

    cont.innerHTML = pedidos.map(p => `
      <div class="card pedido-card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <div>
            <strong>Pedido #${p.id}</strong>
            <span class="text-muted ms-2 small">${formatarData(p.criado_em)}</span>
          </div>
          <span class="badge ${badgeStatus(p.status)}">${labelStatus(p.status)}</span>
        </div>
        <div class="card-body">
          <div class="text-muted small mb-2">${p.itens ? p.itens.map(i => `${i.quantidade}x ${i.nome_produto}`).join(', ') : ''}</div>
          <div class="d-flex justify-content-between align-items-center">
            <strong class="text-primary">${formatarMoeda(p.total)}</strong>
            <button class="btn btn-outline-secondary btn-sm" onclick="verDetalhes(${p.id})">
              <i class="bi bi-eye"></i> Detalhes
            </button>
          </div>
        </div>
      </div>
    `).join('');

  } catch {
    cont.innerHTML = '<div class="alert alert-danger">Erro ao carregar pedidos.</div>';
  }
}

async function verDetalhes(id) {
  const corpo = document.getElementById('modal-detalhes-body');
  corpo.innerHTML = '<div class="text-center py-3"><div class="spinner-border text-primary"></div></div>';
  new bootstrap.Modal(document.getElementById('modalDetalhes')).show();

  try {
    const resp = await fetch(`${API_URL}/pedidos/${id}`, { headers: authHeaders() });
    const p = await resp.json();

    corpo.innerHTML = `
      <div class="mb-3">
        <span class="badge ${badgeStatus(p.status)} mb-2">${labelStatus(p.status)}</span>
        <p class="text-muted small mb-1">Realizado em: ${formatarData(p.criado_em)}</p>
      </div>
      <table class="table table-sm">
        <thead><tr><th>Item</th><th>Qtd</th><th>Preço</th></tr></thead>
        <tbody>
          ${(p.itens || []).map(i => `
            <tr>
              <td>${i.nome_produto}</td>
              <td>${i.quantidade}</td>
              <td>${formatarMoeda(i.preco_unitario * i.quantidade)}</td>
            </tr>
          `).join('')}
        </tbody>
        <tfoot>
          <tr><td colspan="2"><strong>Total</strong></td><td><strong>${formatarMoeda(p.total)}</strong></td></tr>
        </tfoot>
      </table>
    `;
  } catch {
    corpo.innerHTML = '<div class="alert alert-danger">Erro ao carregar detalhes.</div>';
  }
}

function badgeStatus(status) {
  return `badge-${status}`;
}

function labelStatus(status) {
  const labels = {
    pendente: 'Pendente',
    em_preparo: 'Em Preparo',
    pronto: 'Pronto',
    entregue: 'Entregue',
    cancelado: 'Cancelado'
  };
  return labels[status] || status;
}

function formatarData(iso) {
  if (!iso) return '-';
  return new Date(iso).toLocaleString('pt-BR');
}

function formatarMoeda(valor) {
  return parseFloat(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}
