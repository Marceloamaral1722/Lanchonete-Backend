let produtoParaExcluir = null;

document.addEventListener('DOMContentLoaded', () => {
  if (!checarAuth(true)) return;
  carregarEstatisticas();
  carregarProdutosAdmin();
  carregarPedidosAdmin();
});

// ─── Abas ───
function mostrarAba(aba, btn) {
  ['produtos', 'pedidos'].forEach(a => {
    document.getElementById(`aba-${a}`).classList.add('d-none');
  });
  document.querySelectorAll('#adminTabs .nav-link').forEach(b => b.classList.remove('active'));
  document.getElementById(`aba-${aba}`).classList.remove('d-none');
  btn.classList.add('active');
}

// ─── Estatísticas ───
async function carregarEstatisticas() {
  try {
    const [rProd, rPed] = await Promise.all([
      fetch(`${API_URL}/produtos`, { headers: authHeaders() }),
      fetch(`${API_URL}/pedidos`, { headers: authHeaders() })
    ]);
    const produtos = await rProd.json();
    const pedidos = await rPed.json();

    document.getElementById('total-produtos').textContent = produtos.length;

    const pendentes = pedidos.filter(p => p.status === 'pendente' || p.status === 'em_preparo').length;
    document.getElementById('pedidos-pendentes').textContent = pendentes;

    const hoje = new Date().toLocaleDateString('pt-BR');
    const entreguesHoje = pedidos.filter(p => p.status === 'entregue' && new Date(p.criado_em).toLocaleDateString('pt-BR') === hoje).length;
    document.getElementById('pedidos-hoje').textContent = entreguesHoje;

    const faturamento = pedidos
      .filter(p => p.status === 'entregue' && new Date(p.criado_em).toLocaleDateString('pt-BR') === hoje)
      .reduce((acc, p) => acc + parseFloat(p.total || 0), 0);
    document.getElementById('faturamento-hoje').textContent = formatarMoeda(faturamento);
  } catch { /* silencia */ }
}

// ─── Produtos Admin ───
async function carregarProdutosAdmin() {
  const tbody = document.getElementById('tabela-produtos');
  try {
    const resp = await fetch(`${API_URL}/produtos`, { headers: authHeaders() });
    const produtos = await resp.json();

    if (!produtos.length) {
      tbody.innerHTML = '<tr><td colspan="7"><div class="empty-state"><i class="bi bi-box-seam"></i><p>Nenhum produto cadastrado.</p></div></td></tr>';
      return;
    }

    tbody.innerHTML = produtos.map(p => `
      <tr>
        <td>${p.id}</td>
        <td><strong>${p.nome}</strong></td>
        <td><span class="badge bg-light text-dark">${p.categoria}</span></td>
        <td>${formatarMoeda(p.preco)}</td>
        <td>${p.estoque}</td>
        <td>
          <span class="badge ${p.ativo ? 'bg-success' : 'bg-secondary'}">${p.ativo ? 'Ativo' : 'Inativo'}</span>
        </td>
        <td>
          <button class="btn btn-sm btn-outline-primary me-1" onclick="editarProduto(${p.id})"><i class="bi bi-pencil"></i></button>
          <button class="btn btn-sm btn-outline-danger" onclick="confirmarExclusao(${p.id})"><i class="bi bi-trash"></i></button>
        </td>
      </tr>
    `).join('');
  } catch {
    tbody.innerHTML = '<tr><td colspan="7" class="text-danger text-center">Erro ao carregar produtos.</td></tr>';
  }
}

function abrirModalProduto(produto = null) {
  document.getElementById('produto-id').value = produto?.id || '';
  document.getElementById('produto-nome').value = produto?.nome || '';
  document.getElementById('produto-descricao').value = produto?.descricao || '';
  document.getElementById('produto-preco').value = produto?.preco || '';
  document.getElementById('produto-estoque').value = produto?.estoque ?? '';
  document.getElementById('produto-categoria').value = produto?.categoria || '';
  document.getElementById('produto-ativo').checked = produto ? produto.ativo : true;
  document.getElementById('modal-produto-titulo').textContent = produto ? 'Editar Produto' : 'Novo Produto';
  new bootstrap.Modal(document.getElementById('modalProduto')).show();
}

async function editarProduto(id) {
  try {
    const resp = await fetch(`${API_URL}/produtos/${id}`, { headers: authHeaders() });
    const produto = await resp.json();
    abrirModalProduto(produto);
  } catch { alert('Erro ao carregar produto.'); }
}

async function salvarProduto() {
  const id = document.getElementById('produto-id').value;
  const body = {
    nome: document.getElementById('produto-nome').value,
    descricao: document.getElementById('produto-descricao').value,
    preco: parseFloat(document.getElementById('produto-preco').value),
    estoque: parseInt(document.getElementById('produto-estoque').value),
    categoria: document.getElementById('produto-categoria').value,
    ativo: document.getElementById('produto-ativo').checked
  };

  const btn = document.getElementById('btn-salvar-produto');
  btn.disabled = true;

  try {
    const resp = await fetch(id ? `${API_URL}/produtos/${id}` : `${API_URL}/produtos`, {
      method: id ? 'PUT' : 'POST',
      headers: authHeaders(),
      body: JSON.stringify(body)
    });

    if (resp.ok) {
      bootstrap.Modal.getInstance(document.getElementById('modalProduto')).hide();
      carregarProdutosAdmin();
      carregarEstatisticas();
    } else {
      const data = await resp.json();
      alert(data.message || 'Erro ao salvar produto.');
    }
  } catch { alert('Erro de conexão.'); }
  finally { btn.disabled = false; }
}

function confirmarExclusao(id) {
  produtoParaExcluir = id;
  new bootstrap.Modal(document.getElementById('modalExcluir')).show();
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-confirmar-excluir').addEventListener('click', async () => {
    if (!produtoParaExcluir) return;
    try {
      const resp = await fetch(`${API_URL}/produtos/${produtoParaExcluir}`, {
        method: 'DELETE',
        headers: authHeaders()
      });
      if (resp.ok) {
        bootstrap.Modal.getInstance(document.getElementById('modalExcluir')).hide();
        carregarProdutosAdmin();
        carregarEstatisticas();
      } else { alert('Erro ao excluir produto.'); }
    } catch { alert('Erro de conexão.'); }
    produtoParaExcluir = null;
  });
});

// ─── Pedidos Admin ───
async function carregarPedidosAdmin() {
  const tbody = document.getElementById('tabela-pedidos');
  const filtroStatus = document.getElementById('filtro-status-pedido')?.value || '';

  let url = `${API_URL}/pedidos`;
  if (filtroStatus) url += `?status=${filtroStatus}`;

  try {
    const resp = await fetch(url, { headers: authHeaders() });
    const pedidos = await resp.json();

    if (!pedidos.length) {
      tbody.innerHTML = '<tr><td colspan="7"><div class="empty-state"><i class="bi bi-receipt"></i><p>Nenhum pedido encontrado.</p></div></td></tr>';
      return;
    }

    tbody.innerHTML = pedidos.map(p => `
      <tr>
        <td>#${p.id}</td>
        <td>${p.nome_usuario || '-'}</td>
        <td class="text-muted small">${p.itens ? p.itens.map(i => `${i.quantidade}x ${i.nome_produto}`).join(', ') : '-'}</td>
        <td><strong>${formatarMoeda(p.total)}</strong></td>
        <td>
          <select class="form-select form-select-sm" onchange="atualizarStatus(${p.id}, this.value)" style="width:130px">
            ${['pendente','em_preparo','pronto','entregue','cancelado'].map(s =>
              `<option value="${s}" ${p.status === s ? 'selected' : ''}>${labelStatus(s)}</option>`
            ).join('')}
          </select>
        </td>
        <td class="small">${formatarData(p.criado_em)}</td>
        <td>
          <button class="btn btn-sm btn-outline-secondary" onclick="verDetalhesPedidoAdmin(${p.id})">
            <i class="bi bi-eye"></i>
          </button>
        </td>
      </tr>
    `).join('');
  } catch {
    tbody.innerHTML = '<tr><td colspan="7" class="text-danger text-center">Erro ao carregar pedidos.</td></tr>';
  }
}

async function atualizarStatus(id, status) {
  try {
    await fetch(`${API_URL}/pedidos/${id}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: JSON.stringify({ status })
    });
    carregarEstatisticas();
  } catch { alert('Erro ao atualizar status.'); }
}

async function verDetalhesPedidoAdmin(id) {
  const corpo = document.getElementById('admin-detalhes-body');
  corpo.innerHTML = '<div class="text-center py-3"><div class="spinner-border text-primary"></div></div>';
  new bootstrap.Modal(document.getElementById('modalDetalhesPedido')).show();

  try {
    const resp = await fetch(`${API_URL}/pedidos/${id}`, { headers: authHeaders() });
    const p = await resp.json();
    corpo.innerHTML = `
      <p><strong>Cliente:</strong> ${p.nome_usuario || '-'}</p>
      <p><strong>Status:</strong> <span class="badge ${badgeStatus(p.status)}">${labelStatus(p.status)}</span></p>
      <table class="table table-sm">
        <thead><tr><th>Item</th><th>Qtd</th><th>Subtotal</th></tr></thead>
        <tbody>
          ${(p.itens || []).map(i => `<tr><td>${i.nome_produto}</td><td>${i.quantidade}</td><td>${formatarMoeda(i.preco_unitario * i.quantidade)}</td></tr>`).join('')}
        </tbody>
        <tfoot><tr><td colspan="2"><strong>Total</strong></td><td><strong>${formatarMoeda(p.total)}</strong></td></tr></tfoot>
      </table>
    `;
  } catch { corpo.innerHTML = '<div class="alert alert-danger">Erro ao carregar detalhes.</div>'; }
}

// ─── Helpers ───
function labelStatus(status) {
  return { pendente: 'Pendente', em_preparo: 'Em Preparo', pronto: 'Pronto', entregue: 'Entregue', cancelado: 'Cancelado' }[status] || status;
}

function badgeStatus(status) { return `badge-${status}`; }

function formatarData(iso) {
  if (!iso) return '-';
  return new Date(iso).toLocaleString('pt-BR');
}

function formatarMoeda(valor) {
  return parseFloat(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}
