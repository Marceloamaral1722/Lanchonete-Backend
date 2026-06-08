import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # ── Banco de dados (XAMPP MySQL) ──
    DB_HOST     = os.getenv('DB_HOST', 'localhost')
    DB_PORT     = os.getenv('DB_PORT', '3306')
    DB_USER     = os.getenv('DB_USER', 'root')
    DB_PASSWORD = os.getenv('DB_PASSWORD', '')
    DB_NAME     = os.getenv('DB_NAME', 'lanchonete_db')

    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # ── JWT ──
    JWT_SECRET_KEY          = os.getenv('JWT_SECRET_KEY', 'maxismus-lanches-secreto-2024')
    JWT_ACCESS_TOKEN_EXPIRES = False  # sem expiração para facilitar o desenvolvimento

    # ── E-mail (Gmail como exemplo) ──
    MAIL_SERVER   = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT     = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS  = True
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', '')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', '')
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', 'noreply@maxismuslanches.com')
