import secrets
from datetime import date
from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_user, logout_user, login_required, current_user
from flask_mail import Message
from models import db, Usuario
from app import mail
from utils import admin_required

auth_bp = Blueprint('auth', __name__)


# ─── Rota raiz: redireciona pelo tipo ───────────────────────────────────────
@auth_bp.route('/')
def index():
    if current_user.is_authenticated:
        if current_user.tipo == 'admin':
            return redirect(url_for('auth.home'))
        return redirect(url_for('auth.cardapio'))
    return redirect(url_for('auth.login'))


# ─── Login / Logout / Cadastro ──────────────────────────────────────────────
@auth_bp.route('/login', methods=['GET'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('auth.index'))
    return render_template('login.html')


@auth_bp.route('/login', methods=['POST'])
def login_post():
    email = request.form.get('email', '').strip()
    senha = request.form.get('senha', '')

    usuario = Usuario.query.filter_by(email=email).first()
    if not usuario or not usuario.checar_senha(senha):
        flash('E-mail ou senha incorretos.', 'danger')
        return redirect(url_for('auth.login'))

    login_user(usuario)
    # Redireciona pelo tipo — NUNCA deixa cliente ir para /home
    if usuario.tipo == 'admin':
        return redirect(url_for('auth.home'))
    return redirect(url_for('auth.cardapio'))


@auth_bp.route('/cadastro', methods=['GET'])
def cadastro():
    if current_user.is_authenticated:
        return redirect(url_for('auth.index'))
    return render_template('cadastro.html')


@auth_bp.route('/cadastro', methods=['POST'])
def cadastro_post():
    nome  = request.form.get('nome', '').strip()
    email = request.form.get('email', '').strip()
    senha = request.form.get('senha', '')

    if Usuario.query.filter_by(email=email).first():
        flash('E-mail ja cadastrado.', 'danger')
        return redirect(url_for('auth.login') + '?aba=cadastro')

    usuario = Usuario(nome=nome, email=email, tipo='comum')
    usuario.set_senha(senha)
    db.session.add(usuario)
    db.session.commit()
    flash('Conta criada! Faca login.', 'success')
    return redirect(url_for('auth.login'))


@auth_bp.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('auth.login'))


@auth_bp.route('/recuperar-senha', methods=['POST'])
def recuperar_senha():
    email = request.form.get('email', '').strip()
    usuario = Usuario.query.filter_by(email=email).first()
    if usuario:
        token = secrets.token_urlsafe(16)
        try:
            msg = Message(
                subject='Recuperacao de Senha - Maxismus Lanches',
                recipients=[email],
                body=f'Seu token de recuperacao: {token}'
            )
            mail.send(msg)
        except Exception:
            pass
    flash('Se o e-mail existir na base, voce recebera as instrucoes.', 'info')
    return redirect(url_for('auth.login'))


# ─── ADMIN: Dashboard operacional ────────────────────────────────────────────
@auth_bp.route('/home')
@admin_required          # ← SOMENTE ADMIN
def home():
    from models import Produto, Cliente, Pedido
    hoje = date.today()

    total_produtos   = Produto.query.count()
    total_clientes   = Cliente.query.count()
    total_pedidos    = Pedido.query.count()
    pendentes        = Pedido.query.filter_by(status='pendente').count()
    em_preparo       = Pedido.query.filter_by(status='em_preparo').count()

    pedidos_hoje     = Pedido.query.filter(db.func.date(Pedido.data_hora) == hoje).all()
    entregues_hoje   = sum(1 for p in pedidos_hoje if p.status == 'entregue')
    faturamento_hoje = sum(p.total for p in pedidos_hoje if p.status == 'entregue')

    from collections import OrderedDict
    ultimos_pedidos  = Pedido.query.order_by(Pedido.id.desc()).limit(20).all()
    ultimos_produtos = Produto.query.order_by(Produto.id.desc()).limit(8).all()
    ultimos_clientes = Cliente.query.order_by(Cliente.id.desc()).limit(8).all()

    # Agrupa ultimos pedidos por cliente para cards no dashboard
    grupos_home = OrderedDict()
    for p in ultimos_pedidos:
        cid = p.cliente_id
        if cid not in grupos_home:
            grupos_home[cid] = {'cliente': p.cliente, 'pedidos': [], 'total': 0}
        grupos_home[cid]['pedidos'].append(p)
        grupos_home[cid]['total'] += p.total

    return render_template('home.html',
                           usuario=current_user,
                           total_produtos=total_produtos,
                           total_clientes=total_clientes,
                           total_pedidos=total_pedidos,
                           pendentes=pendentes,
                           em_preparo=em_preparo,
                           entregues_hoje=entregues_hoje,
                           faturamento_hoje=faturamento_hoje,
                           ultimos_pedidos=ultimos_pedidos,
                           grupos_home=list(grupos_home.values()),
                           ultimos_produtos=ultimos_produtos,
                           ultimos_clientes=ultimos_clientes)


# ─── CLIENTE: Cardapio ────────────────────────────────────────────────────────
@auth_bp.route('/cardapio')
@login_required
def cardapio():
    from models import Produto, Categoria
    # Admin que acessar /cardapio vai para o dashboard
    if current_user.tipo == 'admin':
        return redirect(url_for('auth.home'))
    produtos   = Produto.query.order_by(Produto.nome).all()
    categorias = Categoria.query.order_by(Categoria.nome).all()
    return render_template('cardapio.html',
                           usuario=current_user,
                           produtos=produtos,
                           categorias=categorias)
