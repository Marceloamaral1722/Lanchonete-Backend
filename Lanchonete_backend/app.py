from flask import Flask
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_mail import Mail

from config import Config
from models import db

jwt  = JWTManager()
mail = Mail()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    jwt.init_app(app)
    mail.init_app(app)
    CORS(app, resources={r"/*": {"origins": "*"}})

    from routes.auth       import auth_bp
    from routes.produtos   import produtos_bp
    from routes.pedidos    import pedidos_bp
    from routes.categorias import categorias_bp

    app.register_blueprint(auth_bp,       url_prefix='/auth')
    app.register_blueprint(produtos_bp,   url_prefix='/produtos')
    app.register_blueprint(pedidos_bp,    url_prefix='/pedidos')
    app.register_blueprint(categorias_bp, url_prefix='/categorias')

    with app.app_context():
        db.create_all()
        _seed_admin()

    return app


def _seed_admin():
    from models import Usuario
    if not Usuario.query.filter_by(email='admin@maxismus.com').first():
        admin = Usuario(nome='Admin', email='admin@maxismus.com', admin=True)
        admin.set_senha('admin123')
        db.session.add(admin)
        db.session.commit()


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, port=5000)
