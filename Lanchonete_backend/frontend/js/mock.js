// ─── MODO DEMO — dados falsos para visualizar o frontend sem backend ───

const DEMO_MODE = false;

// ─── Banco de dados falso (em memória) ───
const mockDB = {
  usuarios: [
    { id: 1, nome: 'Admin Lanchonete', email: 'admin@lanches.com', senha: '123456', admin: true },
    { id: 2, nome: 'João Cliente',     email: 'joao@email.com',    senha: '123456', admin: false }
  ],

  produtos: [
    { id: 1, nome: 'X-Burguer',       categoria: 'Lanches',    preco: 18.90, estoque: 50, descricao: 'Hambúrguer artesanal com queijo e salada', ativo: true },
    { id: 2, nome: 'X-Bacon',         categoria: 'Lanches',    preco: 22.50, estoque: 30, descricao: 'Hambúrguer com bacon crocante e cheddar', ativo: true },
    { id: 3, nome: 'X-Frango',        categoria: 'Lanches',    preco: 17.00, estoque: 40, descricao: 'Frango grelhado com alface e tomate', ativo: true },
    { id: 4, nome: 'Coca-Cola 350ml', categoria: 'Bebidas',    preco: 6.00,  estoque: 100, descricao: 'Gelada', ativo: true },
    { id: 5, nome: 'Suco de Laranja', categoria: 'Bebidas',    preco: 8.50,  estoque: 25, descricao: 'Natural, 400ml', ativo: true },
    { id: 6, nome: 'Batata Frita',    categoria: 'Porcoes',    preco: 14.00, estoque: 60, descricao: 'Porção crocante com molho especial', ativo: true },
    { id: 7, nome: 'Onion Rings',     categoria: 'Porcoes',    preco: 15.00, estoque: 35, descricao: 'Anéis de cebola empanados', ativo: true },
    { id: 8, nome: 'Sorvete 2 Bolas', categoria: 'Sobremesas', preco: 10.00, estoque: 20, descricao: 'Escolha 2 sabores', ativo: true },
    { id: 9, nome: 'Combo Família',   categoria: 'Combos',     preco: 55.00, estoque: 15, descricao: '2 X-Burguer + 2 Refrigerantes + 1 Batata', ativo: true }
  ],

  pedidos: [
    {
      id: 1, usuario_id: 2, nome_usuario: 'João Cliente',
      status: 'entregue', total: 43.40,
      criado_em: new Date(Date.now() - 86400000 * 2).toISOString(),
      itens: [
        { nome_produto: 'X-Burguer', quantidade: 2, preco_unitario: 18.90 },
        { nome_produto: 'Coca-Cola 350ml', quantidade: 1, preco_unitario: 6.00 }
      ]
    },
    {
      id: 2, usuario_id: 2, nome_usuario: 'João Cliente',
      status: 'em_preparo', total: 29.00,
      criado_em: new Date(Date.now() - 1800000).toISOString(),
      itens: [
        { nome_produto: 'X-Bacon', quantidade: 1, preco_unitario: 22.50 },
        { nome_produto: 'Suco de Laranja', quantidade: 1, preco_unitario: 8.50 }
      ]
    },
    {
      id: 3, usuario_id: 2, nome_usuario: 'Maria Silva',
      status: 'pendente', total: 69.00,
      criado_em: new Date(Date.now() - 300000).toISOString(),
      itens: [
        { nome_produto: 'Combo Família', quantidade: 1, preco_unitario: 55.00 },
        { nome_produto: 'Sorvete 2 Bolas', quantidade: 1, preco_unitario: 10.00 },
        { nome_produto: 'Coca-Cola 350ml', quantidade: 1, preco_unitario: 6.00 }
      ]
    },
    {
      id: 4, usuario_id: 2, nome_usuario: 'Carlos Lima',
      status: 'pronto', total: 37.50,
      criado_em: new Date(Date.now() - 600000).toISOString(),
      itens: [
        { nome_produto: 'X-Frango', quantidade: 1, preco_unitario: 17.00 },
        { nome_produto: 'Batata Frita', quantidade: 1, preco_unitario: 14.00 },
        { nome_produto: 'Coca-Cola 350ml', quantidade: 1, preco_unitario: 6.00 }
      ]
    }
  ],

  proximoIdProduto: 10,
  proximoIdPedido: 5
};

// ─── Override do fetch global ───
const fetchOriginal = window.fetch;

window.fetch = async function (url, options = {}) {
  if (!DEMO_MODE) return fetchOriginal(url, options);

  const method  = (options.method || 'GET').toUpperCase();
  const body    = options.body ? JSON.parse(options.body) : {};
  const path    = url.replace(API_URL, '').split('?')[0];
  const query   = url.includes('?') ? url.split('?')[1] : '';
  const params  = new URLSearchParams(query);

  await delay(200); // simula latência de rede

  // ── Auth ──
  if (path === '/auth/login' && method === 'POST') {
    const user = mockDB.usuarios.find(u => u.email === body.email && u.senha === body.senha);
    if (!user) return mockResp({ message: 'E-mail ou senha incorretos.' }, 401);
    const { senha, ...userData } = user;
    return mockResp({ token: 'demo-token-' + user.id, usuario: userData });
  }

  if (path === '/auth/cadastro' && method === 'POST') {
    if (mockDB.usuarios.find(u => u.email === body.email))
      return mockResp({ message: 'E-mail já cadastrado.' }, 409);
    const novo = { id: mockDB.usuarios.length + 1, ...body, admin: false };
    mockDB.usuarios.push(novo);
    return mockResp({ message: 'Conta criada com sucesso!' });
  }

  if (path === '/auth/logout' && method === 'POST') {
    return mockResp({ message: 'Logout realizado.' });
  }

  if (path === '/auth/recuperar-senha' && method === 'POST') {
    const existe = mockDB.usuarios.find(u => u.email === body.email);
    if (!existe) return mockResp({ message: 'E-mail não encontrado.' }, 404);
    return mockResp({ message: 'E-mail enviado com sucesso.' });
  }

  // ── Produtos ──
  if (path === '/produtos' && method === 'GET') {
    return mockResp(mockDB.produtos.filter(p => p.ativo || isAdmin()));
  }

  if (path === '/produtos' && method === 'POST') {
    const novo = { id: mockDB.proximoIdProduto++, ...body };
    mockDB.produtos.push(novo);
    return mockResp(novo);
  }

  const matchProduto = path.match(/^\/produtos\/(\d+)$/);
  if (matchProduto) {
    const id = parseInt(matchProduto[1]);
    const idx = mockDB.produtos.findIndex(p => p.id === id);

    if (method === 'GET') {
      if (idx === -1) return mockResp({ message: 'Produto não encontrado.' }, 404);
      return mockResp(mockDB.produtos[idx]);
    }
    if (method === 'PUT') {
      if (idx === -1) return mockResp({ message: 'Produto não encontrado.' }, 404);
      mockDB.produtos[idx] = { ...mockDB.produtos[idx], ...body };
      return mockResp(mockDB.produtos[idx]);
    }
    if (method === 'DELETE') {
      if (idx === -1) return mockResp({ message: 'Produto não encontrado.' }, 404);
      mockDB.produtos.splice(idx, 1);
      return mockResp({ message: 'Produto excluído.' });
    }
  }

  // ── Pedidos ──
  if (path === '/pedidos' && method === 'GET') {
    let lista = [...mockDB.pedidos];
    const status = params.get('status');
    if (status) lista = lista.filter(p => p.status === status);
    // cliente só vê os próprios pedidos
    if (!isAdmin()) {
      const userId = getUsuarioAtual()?.id;
      lista = lista.filter(p => p.usuario_id === userId);
    }
    return mockResp(lista.sort((a, b) => new Date(b.criado_em) - new Date(a.criado_em)));
  }

  if (path === '/pedidos' && method === 'POST') {
    const usuario = getUsuarioAtual();
    const itens = (body.itens || []).map(item => {
      const prod = mockDB.produtos.find(p => p.id === item.produto_id);
      return { nome_produto: prod?.nome || '?', quantidade: item.quantidade, preco_unitario: prod?.preco || 0 };
    });
    const total = itens.reduce((acc, i) => acc + i.preco_unitario * i.quantidade, 0);
    const novo = {
      id: mockDB.proximoIdPedido++,
      usuario_id: usuario?.id,
      nome_usuario: usuario?.nome,
      status: 'pendente',
      total: parseFloat(total.toFixed(2)),
      criado_em: new Date().toISOString(),
      itens
    };
    mockDB.pedidos.push(novo);
    return mockResp(novo);
  }

  const matchPedido = path.match(/^\/pedidos\/(\d+)$/);
  if (matchPedido) {
    const id = parseInt(matchPedido[1]);
    const idx = mockDB.pedidos.findIndex(p => p.id === id);

    if (method === 'GET') {
      if (idx === -1) return mockResp({ message: 'Pedido não encontrado.' }, 404);
      return mockResp(mockDB.pedidos[idx]);
    }
    if (method === 'PUT') {
      if (idx === -1) return mockResp({ message: 'Pedido não encontrado.' }, 404);
      mockDB.pedidos[idx] = { ...mockDB.pedidos[idx], ...body };
      return mockResp(mockDB.pedidos[idx]);
    }
    if (method === 'DELETE') {
      if (idx === -1) return mockResp({ message: 'Pedido não encontrado.' }, 404);
      mockDB.pedidos[idx].status = 'cancelado';
      return mockResp({ message: 'Pedido cancelado.' });
    }
  }

  // rota não encontrada
  return mockResp({ message: 'Rota não encontrada.' }, 404);
};

// ─── Helpers do mock ───
function mockResp(data, status = 200) {
  return Promise.resolve({
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(data)
  });
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function getUsuarioAtual() {
  try { return JSON.parse(localStorage.getItem('usuario') || 'null'); } catch { return null; }
}

function isAdmin() {
  return getUsuarioAtual()?.admin === true;
}
