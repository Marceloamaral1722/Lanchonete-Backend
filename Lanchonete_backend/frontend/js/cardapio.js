// ─── Estado do carrinho ───
let carrinho = [];
let produtos = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!checarAuth()) return;
  carregarProdutos();
});

// ─── Produtos ───
async function carregarProdutos() {
  try {
    const resp = await fetch(`${API_URL}/produtos`, { headers: authHeaders() });
    const data = await resp.json();
    produtos = data;
    renderizarCategorias(data);
    renderizarProdutos(data);
  } catch {
    document.getElementById('lista-produtos').innerHTML =
      '<div class="col-12"><div class="alert alert-danger">Erro ao carregar cardápio.</div></div>';
  }
}

function renderizarCategorias(lista) {
  const categorias = [...new Set(lista.map(p => p.categoria))];
  const cont = document.getElementById('filtros-categoria');
  cont.innerHTML = `<button class="btn btn-primary btn-sm categoria-btn active" onclick="filtrarCategoria('todos', this)">Todos</button>`;
  categorias.forEach(cat => {
    cont.innerHTML += `<button class="btn btn-sm categoria-btn" onclick="filtrarCategoria('${cat}', this)">${cat}</button>`;
  });
}

function filtrarCategoria(categoria, btn) {
  document.querySelectorAll('.categoria-btn').forEach(b => b.classList.remove('btn-primary', 'active'));
  btn.classList.add('btn-primary', 'active');
  const filtrados = categoria === 'todos' ? produtos : produtos.filter(p => p.categoria === categoria);
  renderizarProdutos(filtrados);
}

function renderizarProdutos(lista) {
  const cont = document.getElementById('lista-produtos');
  if (!lista.length) {
    cont.innerHTML = '<div class="col-12"><div class="empty-state"><i class="bi bi-bag-x"></i><p>Nenhum produto encontrado.</p></div></div>';
    return;
  }
  cont.innerHTML = lista.map(p => `
    <div class="col-6 col-md-4 col-lg-3">
      <div class="card produto-card h-100">
        <div class="produto-img">${emojiCategoria(p.categoria)}</div>
        <div class="card-body d-flex flex-column">
          <span class="badge-categoria mb-1">${p.categoria}</span>
          <h6 class="card-title mb-1" style="font-size:.9rem;font-weight:700">${p.nome}</h6>
          <p class="text-muted mb-2" style="font-size:.75rem;line-height:1.3">${p.descricao || ''}</p>
          <div class="mt-auto d-flex justify-content-between align-items-center">
            <span class="produto-preco">${formatarMoeda(p.preco)}</span>
            <div id="ctrl-${p.id}">${renderControle(p)}</div>
          </div>
        </div>
      </div>
    </div>
  `).join('');
}

function renderControle(p) {
  if (p.estoque <= 0) {
    return `<button class="btn btn-sm btn-secondary" disabled style="font-size:.75rem;padding:.25rem .6rem">Esgotado</button>`;
  }
  const item = carrinho.find(c => c.id === p.id);
  if (!item) {
    return `<button class="btn btn-primary btn-sm" onclick="adicionarAoCarrinho(${p.id})" style="width:34px;height:34px;padding:0;border-radius:50%;font-size:1rem">+</button>`;
  }
  return `
    <div class="card-qty-ctrl">
      <button class="btn btn-outline-danger btn-sm" onclick="removerDoCarrinho(${p.id})"><i class="bi bi-dash"></i></button>
      <input type="number" class="qty-input" value="${item.quantidade}" min="1"
        onchange="setQuantidade(${p.id}, this.value)"
        onblur="setQuantidade(${p.id}, this.value)" />
      <button class="btn btn-primary btn-sm" onclick="adicionarAoCarrinho(${p.id})"><i class="bi bi-plus"></i></button>
    </div>`;
}

function atualizarControleProduto(id) {
  const el = document.getElementById(`ctrl-${id}`);
  if (!el) return;
  const produto = produtos.find(p => p.id === id);
  if (produto) el.innerHTML = renderControle(produto);
}

function emojiCategoria(cat) {
  const mapa = { Lanches: '🍔', Bebidas: '🥤', Porcoes: '🍟', Sobremesas: '🍦', Combos: '🎁' };
  return mapa[cat] || '🍽️';
}

// ─── Carrinho ───
function adicionarAoCarrinho(id) {
  const produto = produtos.find(p => p.id === id);
  if (!produto) return;
  const item = carrinho.find(c => c.id === id);
  if (item) { item.quantidade++; } else { carrinho.push({ ...produto, quantidade: 1 }); }
  atualizarBadgeCarrinho();
  atualizarControleProduto(id);
  if (document.getElementById('offcanvasCarrinho').classList.contains('show')) renderizarCarrinho();
}

function removerDoCarrinho(id) {
  const item = carrinho.find(c => c.id === id);
  if (!item) return;
  if (item.quantidade > 1) { item.quantidade--; } else { carrinho = carrinho.filter(c => c.id !== id); }
  atualizarBadgeCarrinho();
  atualizarControleProduto(id);
  if (document.getElementById('offcanvasCarrinho').classList.contains('show')) renderizarCarrinho();
}

function setQuantidade(id, valor) {
  const qtd = parseInt(valor);
  if (isNaN(qtd) || qtd < 1) { removerDoCarrinho(id); return; }
  const item = carrinho.find(c => c.id === id);
  const produto = produtos.find(p => p.id === id);
  if (!item && produto) { carrinho.push({ ...produto, quantidade: qtd }); }
  else if (item) { item.quantidade = qtd; }
  atualizarBadgeCarrinho();
  atualizarControleProduto(id);
  if (document.getElementById('offcanvasCarrinho').classList.contains('show')) renderizarCarrinho();
}

function atualizarBadgeCarrinho() {
  const total = carrinho.reduce((acc, c) => acc + c.quantidade, 0);
  const badge = document.getElementById('badge-carrinho');
  badge.textContent = total;
  badge.style.display = total > 0 ? 'block' : 'none';
}

function renderizarCarrinho() {
  const cont = document.getElementById('lista-carrinho');
  const btn = document.getElementById('btn-fazer-pedido');

  if (!carrinho.length) {
    cont.innerHTML = '<p class="text-muted text-center mt-4" style="font-size:.9rem">Seu carrinho está vazio</p>';
    document.getElementById('subtotal-carrinho').textContent = 'R$ 0,00';
    btn.disabled = true;
    return;
  }

  let subtotal = 0;
  cont.innerHTML = carrinho.map(item => {
    subtotal += item.preco * item.quantidade;
    return `
      <div class="carrinho-item">
        <div style="flex:1;min-width:0">
          <div class="fw-semibold text-truncate" style="font-size:.88rem">${item.nome}</div>
          <div class="text-muted" style="font-size:.75rem">${formatarMoeda(item.preco)} cada</div>
        </div>
        <div class="carrinho-qtd ms-2">
          <button class="btn btn-outline-secondary btn-sm" onclick="removerDoCarrinho(${item.id})"><i class="bi bi-dash"></i></button>
          <span style="min-width:18px;text-align:center;font-weight:700">${item.quantidade}</span>
          <button class="btn btn-outline-primary btn-sm" onclick="adicionarAoCarrinho(${item.id})"><i class="bi bi-plus"></i></button>
        </div>
      </div>`;
  }).join('');

  document.getElementById('subtotal-carrinho').textContent = formatarMoeda(subtotal);
  btn.disabled = false;
}

function abrirCarrinho() {
  renderizarCarrinho();
  new bootstrap.Offcanvas(document.getElementById('offcanvasCarrinho')).show();
}

// ─── Fazer pedido ───
async function fazerPedido() {
  const itens = carrinho.map(c => ({ produto_id: c.id, quantidade: c.quantidade }));
  try {
    const resp = await fetch(`${API_URL}/pedidos`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ itens })
    });
    if (resp.ok) {
      carrinho = [];
      atualizarBadgeCarrinho();
      // reseta controles de todos os produtos
      produtos.forEach(p => atualizarControleProduto(p.id));
      bootstrap.Offcanvas.getInstance(document.getElementById('offcanvasCarrinho')).hide();
      new bootstrap.Modal(document.getElementById('modalConfirmacao')).show();
    } else {
      const data = await resp.json();
      alert(data.message || 'Erro ao realizar pedido.');
    }
  } catch { alert('Erro de conexão.'); }
}

function formatarMoeda(valor) {
  return parseFloat(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}
