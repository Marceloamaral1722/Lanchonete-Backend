from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()


class Usuario(db.Model, UserMixin):
    __tablename__ = 'usuarios'

    id         = db.Column(db.Integer, primary_key=True)
    nome       = db.Column(db.String(100), nullable=False)
    email      = db.Column(db.String(150), unique=True, nullable=False)
    senha_hash = db.Column(db.String(255), nullable=False)
    tipo       = db.Column(db.String(10), default='comum')  # admin ou comum
    criado_em  = db.Column(db.DateTime, default=datetime.utcnow)

    pedidos = db.relationship('Pedido', backref='usuario', lazy=True)

    def set_senha(self, senha):
        self.senha_hash = generate_password_hash(senha)

    def checar_senha(self, senha):
        return check_password_hash(self.senha_hash, senha)


class Categoria(db.Model):
    __tablename__ = 'categorias'

    id        = db.Column(db.Integer, primary_key=True)
    nome      = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)

    produtos = db.relationship('Produto', backref='categoria', lazy=True)


class Produto(db.Model):
    __tablename__ = 'produtos'

    id           = db.Column(db.Integer, primary_key=True)
    nome         = db.Column(db.String(100), nullable=False)
    descricao    = db.Column(db.Text)
    preco        = db.Column(db.Float, nullable=False)
    estoque      = db.Column(db.Integer, default=0)
    categoria_id = db.Column(db.Integer, db.ForeignKey('categorias.id'), nullable=False)
    criado_em    = db.Column(db.DateTime, default=datetime.utcnow)

    pedidos = db.relationship('Pedido', backref='produto', lazy=True)


class Cliente(db.Model):
    __tablename__ = 'clientes'

    id        = db.Column(db.Integer, primary_key=True)
    nome      = db.Column(db.String(100), nullable=False)
    cpf       = db.Column(db.String(14), unique=True, nullable=False)
    telefone  = db.Column(db.String(20))
    email     = db.Column(db.String(150))
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)

    pedidos = db.relationship('Pedido', backref='cliente', lazy=True)


class Pedido(db.Model):
    __tablename__ = 'pedidos'

    STATUS_OPCOES = ['pendente', 'em_preparo', 'pronto', 'entregue', 'cancelado']

    id          = db.Column(db.Integer, primary_key=True)
    data_hora   = db.Column(db.DateTime, default=datetime.utcnow)
    status      = db.Column(db.String(20), default='pendente')
    observacoes = db.Column(db.Text)
    quantidade  = db.Column(db.Integer, default=1)
    total       = db.Column(db.Float, default=0)
    grupo_id    = db.Column(db.String(16), nullable=True)  # agrupa itens do mesmo carrinho
    cliente_id  = db.Column(db.Integer, db.ForeignKey('clientes.id'), nullable=False)
    produto_id  = db.Column(db.Integer, db.ForeignKey('produtos.id'), nullable=False)
    usuario_id  = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
