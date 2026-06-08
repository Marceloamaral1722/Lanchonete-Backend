from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_required, current_user
from models import db, Categoria
from utils import admin_required

categorias_bp = Blueprint('categorias', __name__)


@categorias_bp.route('/categorias')
@admin_required
def listar_categorias():
    categorias = Categoria.query.order_by(Categoria.nome).all()
    return render_template('categorias/lista.html',
                           usuario=current_user,
                           categorias=categorias)


@categorias_bp.route('/categorias/nova', methods=['GET'])
@admin_required
def nova_categoria():
    return render_template('categorias/form.html',
                           usuario=current_user,
                           categoria=None)


@categorias_bp.route('/categorias/nova', methods=['POST'])
@admin_required
def nova_categoria_post():
    nome      = request.form.get('nome')
    descricao = request.form.get('descricao', '')

    if not nome:
        flash('Nome e obrigatorio.', 'danger')
        return redirect(url_for('categorias.nova_categoria'))

    categoria = Categoria(nome=nome, descricao=descricao)
    db.session.add(categoria)
    db.session.commit()
    flash('Categoria criada com sucesso!', 'success')
    return redirect(url_for('categorias.listar_categorias'))


@categorias_bp.route('/categorias/<int:id>/editar', methods=['GET'])
@admin_required
def editar_categoria(id):
    categoria = Categoria.query.get_or_404(id)
    return render_template('categorias/form.html',
                           usuario=current_user,
                           categoria=categoria)


@categorias_bp.route('/categorias/<int:id>/editar', methods=['POST'])
@admin_required
def editar_categoria_post(id):
    categoria = Categoria.query.get_or_404(id)
    categoria.nome      = request.form.get('nome', categoria.nome)
    categoria.descricao = request.form.get('descricao', categoria.descricao)
    db.session.commit()
    flash('Categoria atualizada!', 'success')
    return redirect(url_for('categorias.listar_categorias'))


@categorias_bp.route('/categorias/<int:id>/deletar', methods=['POST'])
@admin_required
def deletar_categoria(id):
    categoria = Categoria.query.get_or_404(id)
    if categoria.produtos:
        flash('Nao e possivel excluir: existem produtos nesta categoria.', 'danger')
        return redirect(url_for('categorias.listar_categorias'))
    db.session.delete(categoria)
    db.session.commit()
    flash('Categoria excluida.', 'success')
    return redirect(url_for('categorias.listar_categorias'))
