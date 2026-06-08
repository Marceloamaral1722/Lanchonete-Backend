// ─── Helpers de autenticação usados em todas as páginas ───

function getToken() {
  return localStorage.getItem('token');
}

function getUsuario() {
  try { return JSON.parse(localStorage.getItem('usuario') || '{}'); } catch { return {}; }
}

function logout() {
  fetch(`${API_URL}/auth/logout`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${getToken()}` }
  }).finally(() => {
    localStorage.removeItem('token');
    localStorage.removeItem('usuario');
    window.location.href = 'login.html';
  });
}

function checarAuth(requerAdmin = false) {
  const token = getToken();
  if (!token) { window.location.href = 'login.html'; return false; }
  const usuario = getUsuario();
  if (requerAdmin && !usuario.admin) { window.location.href = 'cardapio.html'; return false; }
  const el = document.getElementById('nome-usuario');
  if (el) el.textContent = usuario.nome || '';
  return true;
}

function authHeaders() {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${getToken()}`
  };
}

// ─── Login ───
async function fazerLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value;
  const senha = document.getElementById('login-senha').value;
  const btn = document.getElementById('btn-login');
  const spinner = document.getElementById('spinner-login');

  btn.disabled = true;
  spinner.classList.remove('d-none');

  try {
    const resp = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, senha })
    });

    const data = await resp.json();

    if (resp.ok) {
      localStorage.setItem('token', data.token);
      localStorage.setItem('usuario', JSON.stringify(data.usuario));
      window.location.href = data.usuario.admin ? 'admin.html' : 'cardapio.html';
    } else {
      mostrarAlerta(data.message || 'E-mail ou senha incorretos.');
    }
  } catch {
    mostrarAlerta('Erro de conexão. Verifique se o servidor está rodando.');
  } finally {
    btn.disabled = false;
    spinner.classList.add('d-none');
  }
}

// ─── Cadastro ───
async function fazerCadastro(e) {
  e.preventDefault();
  const nome = document.getElementById('cadastro-nome').value;
  const email = document.getElementById('cadastro-email').value;
  const senha = document.getElementById('cadastro-senha').value;
  const confirmar = document.getElementById('cadastro-confirmar').value;

  if (senha !== confirmar) {
    mostrarAlerta('As senhas não coincidem.');
    return;
  }

  const btn = document.getElementById('btn-cadastro');
  const spinner = document.getElementById('spinner-cadastro');
  btn.disabled = true;
  spinner.classList.remove('d-none');

  try {
    const resp = await fetch(`${API_URL}/auth/cadastro`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nome, email, senha })
    });

    const data = await resp.json();

    if (resp.ok) {
      mostrarAlerta('Conta criada com sucesso! Faça login.', 'success');
      setTimeout(() => showTab('login'), 1500);
    } else {
      mostrarAlerta(data.message || 'Erro ao criar conta.');
    }
  } catch {
    mostrarAlerta('Erro de conexão. Verifique se o servidor está rodando.');
  } finally {
    btn.disabled = false;
    spinner.classList.add('d-none');
  }
}
