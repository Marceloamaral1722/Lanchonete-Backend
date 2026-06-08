BEGIN TRANSACTION;
CREATE TABLE categorias (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	descricao TEXT, 
	criado_em DATETIME, 
	PRIMARY KEY (id)
);
INSERT INTO "categorias" VALUES(1,'Lanches','Hamburgeres e sanduiches artesanais','2026-06-05 18:54:16.076639');
INSERT INTO "categorias" VALUES(2,'Bebidas','Refrigerantes, sucos e vitaminas','2026-06-05 18:54:16.076643');
INSERT INTO "categorias" VALUES(3,'Sobremesas','Sorvetes, bolos e doces','2026-06-05 18:54:16.076644');
CREATE TABLE clientes (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	cpf VARCHAR(14) NOT NULL, 
	telefone VARCHAR(20), 
	email VARCHAR(150), 
	criado_em DATETIME, 
	PRIMARY KEY (id), 
	UNIQUE (cpf)
);
INSERT INTO "clientes" VALUES(1,'Joao da Silva','111.111.111-11','(83) 99111-1111','joao@email.com','2026-06-05 18:54:16.080206');
INSERT INTO "clientes" VALUES(2,'Maria Oliveira','222.222.222-22','(83) 99222-2222','maria@email.com','2026-06-05 18:54:16.080209');
INSERT INTO "clientes" VALUES(3,'Carlos Ferreira','333.333.333-33','(83) 99333-3333','carlos@email.com','2026-06-05 18:54:16.080211');
CREATE TABLE pedidos (
	id INTEGER NOT NULL, 
	data_hora DATETIME, 
	status VARCHAR(20), 
	observacoes TEXT, 
	quantidade INTEGER, 
	total FLOAT, 
	cliente_id INTEGER NOT NULL, 
	produto_id INTEGER NOT NULL, 
	usuario_id INTEGER NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(cliente_id) REFERENCES clientes (id), 
	FOREIGN KEY(produto_id) REFERENCES produtos (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);
INSERT INTO "pedidos" VALUES(1,'2026-06-05 18:54:16.081288','pendente','Sem cebola no primeiro',2,37.8,1,1,1);
INSERT INTO "pedidos" VALUES(2,'2026-06-05 18:54:16.081393','pronto','',3,18.0,2,3,2);
CREATE TABLE produtos (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	descricao TEXT, 
	preco FLOAT NOT NULL, 
	estoque INTEGER, 
	categoria_id INTEGER NOT NULL, 
	criado_em DATETIME, 
	PRIMARY KEY (id), 
	FOREIGN KEY(categoria_id) REFERENCES categorias (id)
);
INSERT INTO "produtos" VALUES(1,'X-Burguer','Hamburguer artesanal com queijo e salada',18.9,50,1,'2026-06-05 18:54:16.078234');
INSERT INTO "produtos" VALUES(2,'X-Bacon','Hamburguer com bacon crocante e cheddar',22.5,30,1,'2026-06-05 18:54:16.078237');
INSERT INTO "produtos" VALUES(3,'Coca-Cola 350ml','Gelada',6.0,100,2,'2026-06-05 18:54:16.078238');
INSERT INTO "produtos" VALUES(4,'Suco de Laranja','Natural 400ml',8.5,40,2,'2026-06-05 18:54:16.078240');
INSERT INTO "produtos" VALUES(5,'Sorvete 2 Bolas','Escolha 2 sabores',10.0,20,3,'2026-06-05 18:54:16.078241');
CREATE TABLE usuarios (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	email VARCHAR(150) NOT NULL, 
	senha_hash VARCHAR(255) NOT NULL, 
	tipo VARCHAR(10), 
	criado_em DATETIME, 
	PRIMARY KEY (id), 
	UNIQUE (email)
);
INSERT INTO "usuarios" VALUES(1,'Administrador','admin@lanchonete.com','scrypt:32768:8:1$5nrIN2SwvsRKOQo4$cc9146b46fea2404906bcb8ae3a4a5f7fb13fce62391ee84a18c7d9a696b935cc01ad7107f905c7b48d2e34f6f156c1404a5f4465d0c3bbdbd55271a337cb744','admin','2026-06-05 18:54:16.073741');
INSERT INTO "usuarios" VALUES(2,'Atendente','user@lanchonete.com','scrypt:32768:8:1$WEjDoM0mKNHhVXMV$10c3f841ea7c0505cba1c4dc3d84ce7cf9e56dd0a5b52749bdd486453ba22d944be5cd90c26cad042910c5243b4e5e7a50449126742a163db31df6c085fa8b41','comum','2026-06-05 18:54:16.073747');
COMMIT;
