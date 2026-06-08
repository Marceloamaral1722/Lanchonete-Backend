from functools import wraps
from flask import redirect, url_for, flash
from flask_login import current_user


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not current_user.is_authenticated or current_user.tipo != 'admin':
            flash('Acesso restrito a administradores.', 'danger')
            return redirect(url_for('auth.cardapio'))
        return f(*args, **kwargs)
    return decorated
