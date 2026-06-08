from flask import Flask
from flask_login import LoginManager
from flask_mail import Mail

from models import db, Usuario

mail = Mail()
login_manager = LoginManager()


def create_app():
    app = Flask(__name__)

    # Configuracoes
    app.config['SECRET_KEY'] = 'maxismus-lanches-chave-secreta'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Flask-Mail (simulado)
    app.config['MAIL_SERVER']   = 'smtp.gmail.com'
    app.config['MAIL_PORT']     = 587
    app.config['MAIL_USE_TLS']  = True
    app.config['MAIL_USERNAME'] = ''
    app.config['MAIL_PASSWORD'] = ''
    app.config['MAIL_DEFAULT_SENDER'] = 'noreply@maxismuslanches.com'

    # Inicializa extensoes
    db.init_app(app)
    mail.init_app(app)

    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = 'Faca login para acessar esta pagina.'
    login_manager.login_message_category = 'warning'

    # Registra blueprints
    from routes.auth        import auth_bp
    from routes.categorias  import categorias_bp
    from routes.produtos    import produtos_bp
    from routes.clientes    import clientes_bp
    from routes.pedidos     import pedidos_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(categorias_bp)
    app.register_blueprint(produtos_bp)
    app.register_blueprint(clientes_bp)
    app.register_blueprint(pedidos_bp)

    # Cria tabelas e popula banco
    with app.app_context():
        db.create_all()
        seed_db()

    return app


@login_manager.user_loader
def load_user(user_id):
    return db.session.get(Usuario, int(user_id))


def seed_db():
    from models import Categoria, Produto, Cliente, Pedido
    from datetime import datetime

    if Usuario.query.count() > 0:
        return  # banco ja populado

    # Usuarios
    admin = Usuario(nome='Administrador', email='admin@lanchonete.com', tipo='admin')
    admin.set_senha('admin123')
    comum = Usuario(nome='Atendente', email='user@lanchonete.com', tipo='comum')
    comum.set_senha('user123')
    db.session.add_all([admin, comum])
    db.session.flush()

    # Categorias
    cat1 = Categoria(nome='Lanches',    descricao='Hamburgeres e sanduiches artesanais')
    cat2 = Categoria(nome='Bebidas',    descricao='Refrigerantes, sucos e vitaminas')
    cat3 = Categoria(nome='Sobremesas', descricao='Sorvetes, bolos e doces')
    db.session.add_all([cat1, cat2, cat3])
    db.session.flush()

    # Produtos
    p1 = Produto(nome='X-Burguer',       descricao='Hamburguer artesanal com queijo e salada', preco=18.90, estoque=50, categoria_id=cat1.id)
    p2 = Produto(nome='X-Bacon',         descricao='Hamburguer com bacon crocante e cheddar',  preco=22.50, estoque=30, categoria_id=cat1.id)
    p3 = Produto(nome='Coca-Cola 350ml', descricao='Gelada',                                   preco=6.00,  estoque=100, categoria_id=cat2.id)
    p4 = Produto(nome='Suco de Laranja', descricao='Natural 400ml',                             preco=8.50,  estoque=40, categoria_id=cat2.id)
    p5 = Produto(nome='Sorvete 2 Bolas', descricao='Escolha 2 sabores',                        preco=10.00, estoque=20, categoria_id=cat3.id)
    db.session.add_all([p1, p2, p3, p4, p5])
    db.session.flush()

    # Clientes
    c1 = Cliente(nome='Joao da Silva',   cpf='111.111.111-11', telefone='(83) 99111-1111', email='joao@email.com')
    c2 = Cliente(nome='Maria Oliveira',  cpf='222.222.222-22', telefone='(83) 99222-2222', email='maria@email.com')
    c3 = Cliente(nome='Carlos Ferreira', cpf='333.333.333-33', telefone='(83) 99333-3333', email='carlos@email.com')
    db.session.add_all([c1, c2, c3])
    db.session.flush()

    # Pedidos
    ped1 = Pedido(cliente_id=c1.id, produto_id=p1.id, usuario_id=admin.id,
                  quantidade=2, total=37.80, status='pendente',
                  observacoes='Sem cebola no primeiro', data_hora=datetime.utcnow())
    ped2 = Pedido(cliente_id=c2.id, produto_id=p3.id, usuario_id=comum.id,
                  quantidade=3, total=18.00, status='pronto',
                  observacoes='', data_hora=datetime.utcnow())
    db.session.add_all([ped1, ped2])
    db.session.commit()

    print('[OK] Banco populado com dados iniciais.')
    print('[OK] Admin: admin@lanchonete.com / admin123')
    print('[OK] User:  user@lanchonete.com  / user123')


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)
