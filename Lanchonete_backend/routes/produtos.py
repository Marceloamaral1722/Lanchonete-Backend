from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from models import db, Produto, Usuario

produtos_bp = Blueprint('produtos', __name__)


def _checar_admin():
    usuario_id = get_jwt_identity()
    usuario = db.session.get(Usuario, int(usuario_id))
    return usuario and usuario.admin


@produtos_bp.route('/', methods=['GET'])
@produtos_bp.route('', methods=['GET'])
@jwt_required()
def listar():
    categoria = request.args.get('categoria', '').strip()
    query = Produto.query
    if not _checar_admin():
        query = query.filter_by(ativo=True)
    if categoria:
        query = query.filter(Produto.categoria.ilike(f'%{categoria}%'))
    produtos = query.order_by(Produto.nome).all()
    return jsonify([p.to_dict() for p in produtos])


@produtos_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    produto = db.get_or_404(Produto, id)
    return jsonify(produto.to_dict())


@produtos_bp.route('/', methods=['POST'])
@produtos_bp.route('', methods=['POST'])
@jwt_required()
def criar():
    if not _checar_admin():
        return jsonify({'message': 'Acesso negado.'}), 403

    dados = request.get_json()
    campos = ['nome', 'preco', 'categoria']
    if not dados or not all(dados.get(c) for c in campos):
        return jsonify({'message': 'Nome, preço e categoria são obrigatórios.'}), 400

    produto = Produto(
        nome       = dados['nome'],
        descricao  = dados.get('descricao', ''),
        preco      = dados['preco'],
        estoque    = dados.get('estoque', 0),
        categoria  = dados['categoria'],
        ativo      = dados.get('ativo', True),
        imagem_url = dados.get('imagem_url')
    )
    db.session.add(produto)
    db.session.commit()
    return jsonify(produto.to_dict()), 201


@produtos_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def atualizar(id):
    if not _checar_admin():
        return jsonify({'message': 'Acesso negado.'}), 403

    produto = db.get_or_404(Produto, id)
    dados   = request.get_json() or {}

    produto.nome       = dados.get('nome',       produto.nome)
    produto.descricao  = dados.get('descricao',  produto.descricao)
    produto.preco      = dados.get('preco',      produto.preco)
    produto.estoque    = dados.get('estoque',    produto.estoque)
    produto.categoria  = dados.get('categoria',  produto.categoria)
    produto.imagem_url = dados.get('imagem_url', produto.imagem_url)

    if 'ativo' in dados:
        produto.ativo = dados['ativo']

    db.session.commit()
    return jsonify(produto.to_dict())


@produtos_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deletar(id):
    if not _checar_admin():
        return jsonify({'message': 'Acesso negado.'}), 403

    produto = db.get_or_404(Produto, id)
    db.session.delete(produto)
    db.session.commit()
    return jsonify({'message': 'Produto excluído com sucesso.'})
