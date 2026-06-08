# Maxismus Lanches — Sistema de Gerenciamento

Projeto avaliativo da disciplina **Backend Frameworks** — UNINASSAU  
Curso: Análise e Desenvolvimento de Sistemas — 3º Período

---

## Como executar o projeto

### 1. Criar e ativar o ambiente virtual

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Instalar as dependências

```bash
pip install -r requirements.txt
```

### 3. Iniciar o servidor

```bash
python app.py
```

### 4. Acessar no navegador

```
http://127.0.0.1:5000
```

---

## Credenciais de acesso

| Perfil | E-mail | Senha |
|---|---|---|
| Administrador | admin@lanchonete.com | admin123 |
| Atendente | user@lanchonete.com | user123 |

---

## Tecnologias utilizadas

- Python 3.x
- Flask (microframework web)
- Flask-SQLAlchemy (ORM)
- Flask-Login (autenticação por sessão)
- Flask-Mail (recuperação de senha)
- Werkzeug (hash de senha)
- Jinja2 (templates HTML)
- SQLite (banco de dados)
- Bootstrap 5 (interface)

---

## Estrutura do projeto

```
Lanchonete_Flask/
├── venv/                    # Ambiente virtual Python
├── app.py                   # Inicialização da aplicação
├── requirements.txt         # Dependências
├── backup_banco.sql         # Backup do banco de dados
├── instance/
│   └── database.db          # Banco de dados SQLite
├── models/
│   └── __init__.py          # Modelos: Usuario, Categoria, Produto, Cliente, Pedido
├── routes/
│   ├── auth.py              # Login, cadastro, logout, recuperação de senha
│   ├── categorias.py        # CRUD de categorias
│   ├── produtos.py          # CRUD de produtos
│   ├── clientes.py          # CRUD de clientes
│   └── pedidos.py           # CRUD de pedidos
├── templates/
│   ├── base.html            # Template mãe (herança Jinja2)
│   ├── login.html           # Tela de login
│   ├── cadastro.html        # Tela de cadastro
│   ├── home.html            # Dashboard
│   ├── categorias/          # Templates de categorias
│   ├── produtos/            # Templates de produtos
│   ├── clientes/            # Templates de clientes
│   └── pedidos/             # Templates de pedidos
└── static/
    ├── css/style.css        # Estilos personalizados
    └── js/main.js           # Scripts do frontend
```

---

## Tabelas do banco de dados

| Tabela | Descrição |
|---|---|
| `usuarios` | Autenticação (admin e comum) |
| `categorias` | Categorias dos produtos (Lanches, Bebidas, etc.) |
| `produtos` | Itens do cardápio (FK → categorias) |
| `clientes` | Clientes cadastrados |
| `pedidos` | Pedidos realizados (FK → clientes, produtos, usuarios) |
