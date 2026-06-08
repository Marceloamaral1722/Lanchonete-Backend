from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_required, current_user
from models import db, Produto, Categoria
from utils import admin_required

produtos_bp = Blueprint('produtos', __name__)


@produtos_bp.route('/produtos')
@login_required
def listar_produtos():
    """Listagem publica (logado): clientes veem o cardapio, admin veem com acoes."""
    categoria_id = request.args.get('categoria_id', type=int)
    categorias   = Categoria.query.order_by(Categoria.nome).all()
    query        = Produto.query.order_by(Produto.nome)
    if categoria_id:
        query = query.filter_by(categoria_id=categoria_id)
    produtos = query.all()
    return render_template('produtos/lista.html',
                           usuario=current_user,
                           produtos=produtos,
                           categorias=categorias,
                           categoria_atual=categoria_id)


@produtos_bp.route('/produtos/<int:id>')
@login_required
def detalhe_produto(id):
    produto = Produto.query.get_or_404(id)
    return render_template('produtos/detalhe.html',
                           usuario=current_user,
                           produto=produto)


@produtos_bp.route('/produtos/novo', methods=['GET'])
@admin_required
def novo_produto():
    categorias = Categoria.query.order_by(Categoria.nome).all()
    return render_template('produtos/form.html',
                           usuario=current_user,
                           produto=None,
                           categorias=categorias)


@produtos_bp.route('/produtos/novo', methods=['POST'])
@admin_required
def novo_produto_post():
    nome         = request.form.get('nome')
    descricao    = request.form.get('descricao', '')
    preco        = request.form.get('preco')
    estoque      = request.form.get('estoque', 0)
    categoria_id = request.form.get('categoria_id')

    if not nome or not preco or not categoria_id:
        flash('Nome, preco e categoria sao obrigatorios.', 'danger')
        return redirect(url_for('produtos.novo_produto'))

    produto = Produto(
        nome=nome,
        descricao=descricao,
        preco=float(preco),
        estoque=int(estoque),
        categoria_id=int(categoria_id)
    )
    db.session.add(produto)
    db.session.commit()
    flash('Produto criado com sucesso!', 'success')
    return redirect(url_for('produtos.listar_produtos'))


@produtos_bp.route('/produtos/<int:id>/editar', methods=['GET'])
@admin_required
def editar_produto(id):
    produto    = Produto.query.get_or_404(id)
    categorias = Categoria.query.order_by(Categoria.nome).all()
    return render_template('produtos/form.html',
                           usuario=current_user,
                           produto=produto,
                           categorias=categorias)


@produtos_bp.route('/produtos/<int:id>/editar', methods=['POST'])
@admin_required
def editar_produto_post(id):
    produto              = Produto.query.get_or_404(id)
    produto.nome         = request.form.get('nome', produto.nome)
    produto.descricao    = request.form.get('descricao', produto.descricao)
    produto.preco        = float(request.form.get('preco', produto.preco))
    produto.estoque      = int(request.form.get('estoque', produto.estoque))
    produto.categoria_id = int(request.form.get('categoria_id', produto.categoria_id))
    db.session.commit()
    flash('Produto atualizado!', 'success')
    return redirect(url_for('produtos.listar_produtos'))


@produtos_bp.route('/produtos/<int:id>/deletar', methods=['POST'])
@admin_required
def deletar_produto(id):
    produto = Produto.query.get_or_404(id)
    db.session.delete(produto)
    db.session.commit()
    flash('Produto excluido.', 'success')
    return redirect(url_for('produtos.listar_produtos'))
