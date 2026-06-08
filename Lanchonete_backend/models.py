from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()


class Usuario(db.Model):
    __tablename__ = 'usuarios'

    id         = db.Column(db.Integer, primary_key=True)
    nome       = db.Column(db.String(100), nullable=False)
    email      = db.Column(db.String(150), unique=True, nullable=False)
    senha_hash = db.Column(db.String(255), nullable=False)
    admin      = db.Column(db.Boolean, default=False)
    criado_em  = db.Column(db.DateTime, default=datetime.utcnow)

    # token para recuperação de senha
    token_recuperacao  = db.Column(db.String(100), nullable=True)
    token_expiracao    = db.Column(db.DateTime, nullable=True)

    pedidos = db.relationship('Pedido', backref='usuario', lazy=True)

    def set_senha(self, senha):
        self.senha_hash = generate_password_hash(senha)

    def checar_senha(self, senha):
        return check_password_hash(self.senha_hash, senha)

    def to_dict(self):
        return {
            'id':        self.id,
            'nome':      self.nome,
            'email':     self.email,
            'admin':     self.admin,
            'criado_em': self.criado_em.isoformat() if self.criado_em else None
        }


class Produto(db.Model):
    __tablename__ = 'produtos'

    id         = db.Column(db.Integer, primary_key=True)
    nome       = db.Column(db.String(100), nullable=False)
    descricao  = db.Column(db.Text, nullable=True)
    preco      = db.Column(db.Numeric(10, 2), nullable=False)
    estoque    = db.Column(db.Integer, default=0)
    categoria  = db.Column(db.String(50), nullable=False)
    ativo      = db.Column(db.Boolean, default=True)
    imagem_url = db.Column(db.String(500), nullable=True)
    criado_em  = db.Column(db.DateTime, default=datetime.utcnow)

    itens = db.relationship('ItemPedido', backref='produto', lazy=True)

    def to_dict(self):
        return {
            'id':         self.id,
            'nome':       self.nome,
            'descricao':  self.descricao,
            'preco':      float(self.preco),
            'estoque':    self.estoque,
            'categoria':  self.categoria,
            'ativo':      self.ativo,
            'imagem_url': self.imagem_url,
            'criado_em':  self.criado_em.isoformat() if self.criado_em else None
        }


class Pedido(db.Model):
    __tablename__ = 'pedidos'

    STATUS_OPCOES = ['pendente', 'em_preparo', 'pronto', 'entregue', 'cancelado']

    id         = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    status     = db.Column(db.String(20), default='pendente')
    total      = db.Column(db.Numeric(10, 2), default=0)
    criado_em  = db.Column(db.DateTime, default=datetime.utcnow)

    itens = db.relationship('ItemPedido', backref='pedido', lazy=True, cascade='all, delete-orphan')

    def to_dict(self, incluir_itens=False):
        dados = {
            'id':           self.id,
            'usuario_id':   self.usuario_id,
            'nome_usuario': self.usuario.nome if self.usuario else None,
            'status':       self.status,
            'total':        float(self.total),
            'criado_em':    self.criado_em.isoformat() if self.criado_em else None
        }
        if incluir_itens:
            dados['itens'] = [i.to_dict() for i in self.itens]
        else:
            dados['itens'] = [i.to_dict() for i in self.itens]
        return dados


class ItemPedido(db.Model):
    __tablename__ = 'itens_pedido'

    id             = db.Column(db.Integer, primary_key=True)
    pedido_id      = db.Column(db.Integer, db.ForeignKey('pedidos.id'), nullable=False)
    produto_id     = db.Column(db.Integer, db.ForeignKey('produtos.id'), nullable=False)
    quantidade     = db.Column(db.Integer, nullable=False)
    preco_unitario = db.Column(db.Numeric(10, 2), nullable=False)

    def to_dict(self):
        return {
            'id':             self.id,
            'produto_id':     self.produto_id,
            'nome_produto':   self.produto.nome if self.produto else None,
            'quantidade':     self.quantidade,
            'preco_unitario': float(self.preco_unitario)
        }
