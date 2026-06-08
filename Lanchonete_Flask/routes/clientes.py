from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_required, current_user
from models import db, Cliente
from utils import admin_required

clientes_bp = Blueprint('clientes', __name__)


@clientes_bp.route('/clientes')
@admin_required
def listar_clientes():
    clientes = Cliente.query.order_by(Cliente.nome).all()
    return render_template('clientes/lista.html',
                           usuario=current_user,
                           clientes=clientes)


@clientes_bp.route('/clientes/<int:id>')
@admin_required
def detalhe_cliente(id):
    cliente = Cliente.query.get_or_404(id)
    return render_template('clientes/detalhe.html',
                           usuario=current_user,
                           cliente=cliente)


@clientes_bp.route('/clientes/novo', methods=['GET'])
@admin_required
def novo_cliente():
    return render_template('clientes/form.html',
                           usuario=current_user,
                           cliente=None)


@clientes_bp.route('/clientes/novo', methods=['POST'])
@admin_required
def novo_cliente_post():
    nome     = request.form.get('nome')
    cpf      = request.form.get('cpf')
    telefone = request.form.get('telefone', '')
    email    = request.form.get('email', '')

    if not nome or not cpf:
        flash('Nome e CPF sao obrigatorios.', 'danger')
        return redirect(url_for('clientes.novo_cliente'))

    if Cliente.query.filter_by(cpf=cpf).first():
        flash('CPF ja cadastrado.', 'danger')
        return redirect(url_for('clientes.novo_cliente'))

    cliente = Cliente(nome=nome, cpf=cpf, telefone=telefone, email=email)
    db.session.add(cliente)
    db.session.commit()
    flash('Cliente cadastrado com sucesso!', 'success')
    return redirect(url_for('clientes.listar_clientes'))


@clientes_bp.route('/clientes/<int:id>/editar', methods=['GET'])
@admin_required
def editar_cliente(id):
    cliente = Cliente.query.get_or_404(id)
    return render_template('clientes/form.html',
                           usuario=current_user,
                           cliente=cliente)


@clientes_bp.route('/clientes/<int:id>/editar', methods=['POST'])
@admin_required
def editar_cliente_post(id):
    cliente          = Cliente.query.get_or_404(id)
    cliente.nome     = request.form.get('nome', cliente.nome)
    cliente.cpf      = request.form.get('cpf', cliente.cpf)
    cliente.telefone = request.form.get('telefone', cliente.telefone)
    cliente.email    = request.form.get('email', cliente.email)
    db.session.commit()
    flash('Cliente atualizado!', 'success')
    return redirect(url_for('clientes.listar_clientes'))


@clientes_bp.route('/clientes/<int:id>/deletar', methods=['POST'])
@admin_required
def deletar_cliente(id):
    cliente = Cliente.query.get_or_404(id)
    db.session.delete(cliente)
    db.session.commit()
    flash('Cliente removido.', 'success')
    return redirect(url_for('clientes.listar_clientes'))
