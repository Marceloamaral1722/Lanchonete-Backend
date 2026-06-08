from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from models import db, Pedido, ItemPedido, Produto, Usuario

pedidos_bp = Blueprint('pedidos', __name__)


def _usuario_atual():
    return db.session.get(Usuario, int(get_jwt_identity()))


@pedidos_bp.route('/', methods=['GET'])
@pedidos_bp.route('', methods=['GET'])
@jwt_required()
def listar():
    usuario = _usuario_atual()
    status  = request.args.get('status')

    query = Pedido.query
    if not usuario.admin:
        query = query.filter_by(usuario_id=usuario.id)
    if status:
        query = query.filter_by(status=status)

    pedidos = query.order_by(Pedido.criado_em.desc()).all()
    return jsonify([p.to_dict() for p in pedidos])


@pedidos_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    usuario = _usuario_atual()
    pedido  = db.get_or_404(Pedido, id)

    if not usuario.admin and pedido.usuario_id != usuario.id:
        return jsonify({'message': 'Acesso negado.'}), 403

    return jsonify(pedido.to_dict(incluir_itens=True))


@pedidos_bp.route('/', methods=['POST'])
@pedidos_bp.route('', methods=['POST'])
@jwt_required()
def criar():
    usuario = _usuario_atual()
    dados   = request.get_json()

    if not dados or not dados.get('itens'):
        return jsonify({'message': 'O pedido precisa ter pelo menos um item.'}), 400

    pedido = Pedido(usuario_id=usuario.id, status='pendente', total=0)
    db.session.add(pedido)
    db.session.flush()  # gera o id do pedido antes de commit

    total = 0
    for item_dados in dados['itens']:
        produto = db.session.get(Produto, item_dados.get('produto_id'))
        if not produto or not produto.ativo:
            db.session.rollback()
            return jsonify({'message': f'Produto inválido ou indisponível.'}), 400

        quantidade = int(item_dados.get('quantidade', 1))
        if produto.estoque < quantidade:
            db.session.rollback()
            return jsonify({'message': f'Estoque insuficiente para "{produto.nome}".'}), 400

        item = ItemPedido(
            pedido_id      = pedido.id,
            produto_id     = produto.id,
            quantidade     = quantidade,
            preco_unitario = produto.preco
        )
        produto.estoque -= quantidade
        total += float(produto.preco) * quantidade
        db.session.add(item)

    pedido.total = round(total, 2)
    db.session.commit()
    return jsonify(pedido.to_dict(incluir_itens=True)), 201


@pedidos_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def atualizar(id):
    usuario = _usuario_atual()
    pedido  = db.get_or_404(Pedido, id)
    dados   = request.get_json() or {}

    if usuario.admin:
        if 'status' in dados:
            if dados['status'] not in Pedido.STATUS_OPCOES:
                return jsonify({'message': 'Status inválido.'}), 400
            pedido.status = dados['status']
    else:
        if pedido.usuario_id != usuario.id:
            return jsonify({'message': 'Acesso negado.'}), 403
        if dados.get('status') == 'cancelado' and pedido.status == 'pendente':
            pedido.status = 'cancelado'
            _devolver_estoque(pedido)
        else:
            return jsonify({'message': 'Apenas pedidos pendentes podem ser cancelados.'}), 400

    db.session.commit()
    return jsonify(pedido.to_dict())


@pedidos_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deletar(id):
    usuario = _usuario_atual()
    if not usuario.admin:
        return jsonify({'message': 'Acesso negado.'}), 403

    pedido = db.get_or_404(Pedido, id)
    db.session.delete(pedido)
    db.session.commit()
    return jsonify({'message': 'Pedido removido.'})


def _devolver_estoque(pedido):
    for item in pedido.itens:
        produto = db.session.get(Produto, item.produto_id)
        if produto:
            produto.estoque += item.quantidade
