import json
import secrets
from flask import Blueprint, render_template, redirect, url_for, request, flash, abort
from flask_login import login_required, current_user
from models import db, Pedido, Cliente, Produto
from utils import admin_required

pedidos_bp = Blueprint('pedidos', __name__)


@pedidos_bp.route('/pedidos')
@login_required
def listar_pedidos():
    if current_user.tipo == 'admin':
        filtro_status = request.args.get('status', '')
        query = Pedido.query.order_by(Pedido.data_hora.desc())
        if filtro_status:
            query = query.filter_by(status=filtro_status)
        pedidos = query.all()

        from collections import OrderedDict
        grupos_cliente = OrderedDict()
        for p in pedidos:
            key = p.grupo_id if p.grupo_id else f'solo_{p.id}'
            if key not in grupos_cliente:
                grupos_cliente[key] = {'cliente': p.cliente, 'pedidos': [], 'total': 0, 'data_hora': p.data_hora}
            grupos_cliente[key]['pedidos'].append(p)
            grupos_cliente[key]['total'] += p.total

        return render_template('pedidos/lista.html',
                               usuario=current_user,
                               pedidos=pedidos,
                               grupos_cliente=list(grupos_cliente.values()),
                               filtro_status=filtro_status,
                               status_opcoes=Pedido.STATUS_OPCOES)
    else:
        pedidos = Pedido.query.filter_by(usuario_id=current_user.id)\
                              .order_by(Pedido.data_hora.desc()).all()
        grupos = {}
        sem_grupo = []
        for p in pedidos:
            if p.grupo_id:
                if p.grupo_id not in grupos:
                    grupos[p.grupo_id] = []
                grupos[p.grupo_id].append(p)
            else:
                sem_grupo.append([p])

        grupos_lista = list(grupos.values()) + sem_grupo
        grupos_lista.sort(key=lambda g: g[0].data_hora or 0, reverse=True)

        return render_template('pedidos/lista.html',
                               usuario=current_user,
                               pedidos=pedidos,
                               grupos=grupos_lista)


@pedidos_bp.route('/pedidos/novo', methods=['GET'])
@login_required
def novo_pedido():
    clientes = Cliente.query.order_by(Cliente.nome).all()
    produtos  = Produto.query.order_by(Produto.nome).all()
    produto_id = request.args.get('produto_id', type=int)
    return render_template('pedidos/form.html',
                           usuario=current_user,
                           pedido=None,
                           clientes=clientes,
                           produtos=produtos,
                           produto_pre=produto_id,
                           status_opcoes=Pedido.STATUS_OPCOES)


@pedidos_bp.route('/pedidos/novo', methods=['POST'])
@login_required
def novo_pedido_post():
    cliente_id  = request.form.get('cliente_id')
    produto_id  = request.form.get('produto_id')
    quantidade  = int(request.form.get('quantidade', 1))
    observacoes = request.form.get('observacoes', '')

    if not cliente_id or not produto_id:
        flash('Cliente e produto sao obrigatorios.', 'danger')
        return redirect(url_for('pedidos.novo_pedido'))

    produto = Produto.query.get_or_404(int(produto_id))
    total   = produto.preco * quantidade

    pedido = Pedido(
        cliente_id  = int(cliente_id),
        produto_id  = int(produto_id),
        usuario_id  = current_user.id,
        quantidade  = quantidade,
        total       = total,
        observacoes = observacoes,
        status      = 'pendente'
    )
    db.session.add(pedido)
    db.session.commit()
    flash('Pedido realizado! Acompanhe o status em Meus Pedidos.', 'success')

    return redirect(url_for('pedidos.listar_pedidos'))


@pedidos_bp.route('/pedidos/<int:id>/editar', methods=['GET'])
@login_required
def editar_pedido(id):
    pedido = Pedido.query.get_or_404(id)
    if current_user.tipo != 'admin' and pedido.usuario_id != current_user.id:
        flash('Voce nao tem permissao para editar este pedido.', 'danger')
        return redirect(url_for('pedidos.listar_pedidos'))
    clientes = Cliente.query.order_by(Cliente.nome).all()
    produtos  = Produto.query.order_by(Produto.nome).all()
    return render_template('pedidos/form.html',
                           usuario=current_user,
                           pedido=pedido,
                           clientes=clientes,
                           produtos=produtos,
                           produto_pre=None,
                           status_opcoes=Pedido.STATUS_OPCOES)


@pedidos_bp.route('/pedidos/<int:id>/editar', methods=['POST'])
@login_required
def editar_pedido_post(id):
    pedido = Pedido.query.get_or_404(id)
    if current_user.tipo != 'admin' and pedido.usuario_id != current_user.id:
        flash('Voce nao tem permissao.', 'danger')
        return redirect(url_for('pedidos.listar_pedidos'))

    pedido.cliente_id  = int(request.form.get('cliente_id', pedido.cliente_id))
    pedido.produto_id  = int(request.form.get('produto_id', pedido.produto_id))
    pedido.quantidade  = int(request.form.get('quantidade', pedido.quantidade))
    pedido.observacoes = request.form.get('observacoes', pedido.observacoes)

    if current_user.tipo == 'admin':
        pedido.status = request.form.get('status', pedido.status)

    pedido.total = pedido.produto.preco * pedido.quantidade
    db.session.commit()
    flash('Pedido atualizado!', 'success')

    if current_user.tipo == 'admin':
        return redirect(url_for('pedidos.listar_pedidos'))
    return redirect(url_for('auth.cardapio'))


@pedidos_bp.route('/carrinho/finalizar', methods=['POST'])
@login_required
def finalizar_carrinho():
    carrinho_json = request.form.get('carrinho', '[]')
    observacoes   = request.form.get('observacoes', '')

    try:
        itens = json.loads(carrinho_json)
    except Exception:
        flash('Carrinho invalido.', 'danger')
        return redirect(url_for('auth.cardapio'))

    if not itens:
        flash('Seu carrinho esta vazio.', 'warning')
        return redirect(url_for('auth.cardapio'))

    cliente = Cliente.query.filter_by(email=current_user.email).first()
    if not cliente:
        cliente = Cliente(
            nome     = current_user.nome,
            cpf      = f'000.000.000-{current_user.id:02d}',
            telefone = '',
            email    = current_user.email
        )
        db.session.add(cliente)
        db.session.flush()

    grupo = secrets.token_hex(8)

    criados = 0
    for item in itens:
        produto_id = int(item.get('produto_id', 0))
        quantidade = int(item.get('quantidade', 1))
        produto    = Produto.query.get(produto_id)
        if not produto or quantidade < 1:
            continue
        pedido = Pedido(
            cliente_id  = cliente.id,
            produto_id  = produto.id,
            usuario_id  = current_user.id,
            quantidade  = quantidade,
            total       = produto.preco * quantidade,
            observacoes = observacoes,
            status      = 'pendente',
            grupo_id    = grupo
        )
        db.session.add(pedido)
        criados += 1

    if criados:
        db.session.commit()
        flash(f'Pedido realizado! {criados} item(ns) enviado(s) para preparo.', 'success')
    else:
        flash('Nenhum item valido no carrinho.', 'danger')

    return redirect(url_for('pedidos.listar_pedidos'))


@pedidos_bp.route('/pedidos/<int:id>/deletar', methods=['POST'])
@admin_required
def deletar_pedido(id):
    pedido = Pedido.query.get_or_404(id)
    db.session.delete(pedido)
    db.session.commit()
    flash('Pedido removido.', 'success')
    return redirect(url_for('pedidos.listar_pedidos'))
