import secrets
from datetime import date, datetime, timedelta
from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_user, logout_user, login_required, current_user
from flask_mail import Message
from models import db, Usuario
from app import mail
from utils import admin_required

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/')
def index():
    if current_user.is_authenticated:
        if current_user.tipo == 'admin':
            return redirect(url_for('auth.home'))
        return redirect(url_for('auth.cardapio'))
    return redirect(url_for('auth.login'))


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
    from models import Cliente
    nome     = request.form.get('nome', '').strip()
    email    = request.form.get('email', '').strip()
    telefone = request.form.get('telefone', '').strip()
    senha    = request.form.get('senha', '')

    if Usuario.query.filter_by(email=email).first():
        flash('E-mail ja cadastrado.', 'danger')
        return redirect(url_for('auth.login') + '?aba=cadastro')

    usuario = Usuario(nome=nome, email=email, tipo='comum')
    usuario.set_senha(senha)
    db.session.add(usuario)

    cliente = Cliente(nome=nome, email=email, telefone=telefone or None)
    db.session.add(cliente)

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
    if not usuario:
        flash('E-mail não encontrado.', 'danger')
        return redirect(url_for('auth.login'))

    token = secrets.token_urlsafe(16)
    usuario.token_recuperacao = token
    usuario.token_expiracao   = datetime.utcnow() + timedelta(hours=1)
    db.session.commit()
    return redirect(url_for('auth.redefinir_senha', token=token))


@auth_bp.route('/redefinir/<token>', methods=['GET'])
def redefinir_senha(token):
    usuario = Usuario.query.filter_by(token_recuperacao=token).first()
    if not usuario or (usuario.token_expiracao and usuario.token_expiracao < datetime.utcnow()):
        flash('Link inválido ou expirado. Solicite um novo.', 'danger')
        return redirect(url_for('auth.login'))
    return render_template('redefinir_senha.html', token=token)


@auth_bp.route('/redefinir/<token>', methods=['POST'])
def redefinir_senha_post(token):
    usuario = Usuario.query.filter_by(token_recuperacao=token).first()
    if not usuario or (usuario.token_expiracao and usuario.token_expiracao < datetime.utcnow()):
        flash('Link inválido ou expirado.', 'danger')
        return redirect(url_for('auth.login'))
    nova_senha = request.form.get('nova_senha', '')
    if len(nova_senha) < 4:
        flash('A senha deve ter pelo menos 4 caracteres.', 'danger')
        return render_template('redefinir_senha.html', token=token)
    usuario.set_senha(nova_senha)
    usuario.token_recuperacao = None
    usuario.token_expiracao   = None
    db.session.commit()
    flash('Senha redefinida com sucesso! Faça login.', 'success')
    return redirect(url_for('auth.login'))


@auth_bp.route('/perfil', methods=['GET'])
@login_required
def perfil():
    return render_template('perfil.html', usuario=current_user)


@auth_bp.route('/perfil/dados', methods=['POST'])
@login_required
def perfil_dados():
    current_user.nome     = request.form.get('nome', current_user.nome).strip()
    current_user.telefone = request.form.get('telefone', '').strip() or None
    db.session.commit()
    flash('Dados atualizados com sucesso!', 'success')
    return redirect(url_for('auth.perfil'))


@auth_bp.route('/perfil/email', methods=['POST'])
@login_required
def perfil_email():
    novo_email = request.form.get('email', '').strip()
    senha      = request.form.get('senha', '')
    if not current_user.checar_senha(senha):
        flash('Senha incorreta.', 'danger')
        return redirect(url_for('auth.perfil'))
    if Usuario.query.filter_by(email=novo_email).first():
        flash('Este e-mail ja esta em uso.', 'danger')
        return redirect(url_for('auth.perfil'))
    current_user.email = novo_email
    db.session.commit()
    flash('E-mail atualizado com sucesso!', 'success')
    return redirect(url_for('auth.perfil'))


@auth_bp.route('/perfil/senha', methods=['POST'])
@login_required
def perfil_senha():
    senha_atual = request.form.get('senha_atual', '')
    nova_senha  = request.form.get('nova_senha', '')
    if not current_user.checar_senha(senha_atual):
        flash('Senha atual incorreta.', 'danger')
        return redirect(url_for('auth.perfil'))
    if len(nova_senha) < 4:
        flash('A nova senha deve ter pelo menos 4 caracteres.', 'danger')
        return redirect(url_for('auth.perfil'))
    current_user.set_senha(nova_senha)
    db.session.commit()
    flash('Senha alterada com sucesso!', 'success')
    return redirect(url_for('auth.perfil'))


@auth_bp.route('/home')
@admin_required
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

    grupos_home = OrderedDict()
    for p in ultimos_pedidos:
        key = p.grupo_id if p.grupo_id else f'solo_{p.id}'
        if key not in grupos_home:
            grupos_home[key] = {'cliente': p.cliente, 'pedidos': [], 'total': 0, 'data_hora': p.data_hora}
        grupos_home[key]['pedidos'].append(p)
        grupos_home[key]['total'] += p.total

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


@auth_bp.route('/cardapio')
@login_required
def cardapio():
    from models import Produto, Categoria
    if current_user.tipo == 'admin':
        return redirect(url_for('auth.home'))
    produtos   = Produto.query.order_by(Produto.nome).all()
    categorias = Categoria.query.order_by(Categoria.nome).all()
    return render_template('cardapio.html',
                           usuario=current_user,
                           produtos=produtos,
                           categorias=categorias)
