from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required

from models import db, Produto

categorias_bp = Blueprint('categorias', __name__)


@categorias_bp.route('/', methods=['GET'])
@categorias_bp.route('', methods=['GET'])
@jwt_required()
def listar():
    """Retorna lista única de categorias cadastradas nos produtos ativos."""
    rows = (
        db.session.query(Produto.categoria)
        .filter_by(ativo=True)
        .distinct()
        .order_by(Produto.categoria)
        .all()
    )
    categorias = [r[0] for r in rows if r[0]]
    return jsonify(categorias)
