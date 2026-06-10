import secrets
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from flask_mail import Message

from models import db, Usuario
from app import mail

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['POST'])
def login():
    dados = request.get_json()
    if not dados or not dados.get('email') or not dados.get('senha'):
        return jsonify({'message': 'E-mail e senha são obrigatórios.'}), 400

    usuario = Usuario.query.filter_by(email=dados['email']).first()
    if not usuario or not usuario.checar_senha(dados['senha']):
        return jsonify({'message': 'E-mail ou senha incorretos.'}), 401

    token = create_access_token(identity=str(usuario.id))
    return jsonify({'token': token, 'usuario': usuario.to_dict()})


@auth_bp.route('/cadastro', methods=['POST'])
def cadastro():
    dados = request.get_json()
    campos = ['nome', 'email', 'senha']
    if not dados or not all(dados.get(c) for c in campos):
        return jsonify({'message': 'Nome, e-mail e senha são obrigatórios.'}), 400

    if Usuario.query.filter_by(email=dados['email']).first():
        return jsonify({'message': 'E-mail já cadastrado.'}), 409

    if len(dados['senha']) < 6:
        return jsonify({'message': 'A senha deve ter pelo menos 6 caracteres.'}), 400

    usuario = Usuario(nome=dados['nome'], email=dados['email'])
    usuario.set_senha(dados['senha'])
    db.session.add(usuario)
    db.session.commit()
    return jsonify({'message': 'Conta criada com sucesso!'}), 201


@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    return jsonify({'message': 'Logout realizado com sucesso.'})


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    usuario_id = get_jwt_identity()
    usuario = db.get_or_404(Usuario, int(usuario_id))
    return jsonify(usuario.to_dict())


@auth_bp.route('/recuperar-senha', methods=['POST'])
def recuperar_senha():
    dados = request.get_json()
    if not dados or not dados.get('email'):
        return jsonify({'message': 'E-mail é obrigatório.'}), 400

    usuario = Usuario.query.filter_by(email=dados['email']).first()
    if not usuario:
        return jsonify({'message': 'E-mail não encontrado.'}), 404

    token = secrets.token_urlsafe(32)
    usuario.token_recuperacao = token
    usuario.token_expiracao   = datetime.utcnow() + timedelta(hours=1)
    db.session.commit()

    _enviar_email_recuperacao(usuario.email, usuario.nome, token)

    return jsonify({'message': 'Instruções enviadas. Use o token para redefinir sua senha.', 'token': token})


@auth_bp.route('/redefinir-senha', methods=['POST'])
def redefinir_senha():
    dados = request.get_json()
    if not dados or not dados.get('token') or not dados.get('nova_senha'):
        return jsonify({'message': 'Token e nova senha são obrigatórios.'}), 400

    usuario = Usuario.query.filter_by(token_recuperacao=dados['token']).first()
    if not usuario:
        return jsonify({'message': 'Token inválido.'}), 400

    if usuario.token_expiracao < datetime.utcnow():
        return jsonify({'message': 'Token expirado. Solicite um novo.'}), 400

    usuario.set_senha(dados['nova_senha'])
    usuario.token_recuperacao = None
    usuario.token_expiracao   = None
    db.session.commit()
    return jsonify({'message': 'Senha redefinida com sucesso!'})


def _enviar_email_recuperacao(email, nome, token):
    try:
        link = f'http://localhost:5000/redefinir/{token}'
        msg = Message(
            subject='Recuperação de Senha — Maxismus Lanches',
            recipients=[email],
            html=f'''
            <h2>Olá, {nome}!</h2>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta.</p>
            <p><a href="{link}" style="background:#EF4444;color:white;padding:10px 20px;
               border-radius:6px;text-decoration:none">Redefinir minha senha</a></p>
            <p>O link expira em 1 hora. Se não solicitou, ignore este e-mail.</p>
            <p>— Equipe Maxismus Lanches</p>
            '''
        )
        mail.send(msg)
    except Exception as e:
        print(f'[AVISO] E-mail nao enviado (configure MAIL_USERNAME/MAIL_PASSWORD no .env): {e}')
