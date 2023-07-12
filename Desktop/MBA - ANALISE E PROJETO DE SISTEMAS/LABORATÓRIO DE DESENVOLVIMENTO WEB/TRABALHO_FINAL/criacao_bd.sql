-- My SQL
create table livro(
    -- chave primária para postgresql
    -- id serial primary key,
    -- chave primária para mysql
    id bigint primary key auto_increment,
    isbn varchar(13) not null unique,
    titulo varchar(200) not null,
    autoria varchar(200) not null,
    editora varchar(100) not null,
    categoria varchar(100) not null,
    preco_venda decimal(15, 2) not null
);


-- Postgres

CREATE DATABASE "trabalho_ldw"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Portuguese_Brazil.1252'
    LC_CTYPE = 'Portuguese_Brazil.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


CREATE SCHEMA IF NOT EXISTS livraria
    AUTHORIZATION postgres;

-- criação de sequência para incremento do id
create sequence log_livro_id_seq;
create sequence livro_identificador;

-- tabela de livro 

drop table if exists "livraria".livro;
create table "livraria".livro (
id bigint primary key NOT NULL,
isbn varchar(13) not null unique,
titulo varchar(200) not null,
autoria varchar(200) not null,
editora varchar(100) not null,
categoria varchar(100) not null,
preco_venda decimal(15, 2) not null

);

alter table "livraria".livro alter column id set default
	nextval('livro_identificador');


drop table if exists livraria.log_livro;
create table if not exists livraria.log_livro(
	log_livro_id integer  primary key,
	log_livro_data_alteracao timestamp,
	log_livro_alteracao varchar(10),
	
	livro_id_old bigint,
	livro_isbn_old varchar(13),
	livro_titulo_old varchar(200),
	livro_autoria_old varchar(200),
	livro_editora_old varchar(100),
	livro_categoria_old varchar(100),
	livro_preco_venda_old decimal(15, 2),
	
	livro_id_new bigint,
	livro_isbn_new varchar(13),
	livro_titulo_new varchar(200),
	livro_autoria_new varchar(200),
	livro_editora_new varchar(100),
	livro_categoria_new varchar(100),
	livro_preco_venda_new decimal(15, 2)
);


alter table livraria.log_livro alter column log_livro_id set default
	nextval('log_livro_id_seq');

-- /////////////////////////////////////////////////////////////////

create or replace function gera_log_livro()
returns trigger as
$$
begin

	if tg_op = 'INSERT' then
		insert into livraria.log_livro(
			log_livro_data_alteracao,
			log_livro_alteracao,
			livro_id_new,
			livro_isbn_new,
			livro_titulo_new,
			livro_autoria_new,
			livro_editora_new,
			livro_categoria_new,
			livro_preco_venda_new)
		
		values (
			now(),
			tg_op,
			new.id,
			new.isbn,
			new.titulo,
			new.autoria,
			new.editora,
			new.categoria,
			new.preco_venda);
				
				return new;
				
	elsif tg_op = 'UPDATE' then
		insert into livraria.log_livro(
			log_livro_data_alteracao,
			log_livro_alteracao,
			livro_id_old,
			livro_isbn_old,
			livro_titulo_old,
			livro_autoria_old,
			livro_editora_old,
			livro_categoria_old,
			livro_preco_venda_old,
			livro_id_new,
			livro_isbn_new,
			livro_titulo_new,
			livro_autoria_new,
			livro_editora_new,
			livro_categoria_new,
			livro_preco_venda_new)
			
		values (
			now(),
			tg_op,
			old.id,
			old.isbn,
			old.titulo,
			old.autoria,
			old.editora,
			old.categoria,
			old.preco_venda,
			new.id,
			new.isbn,
			new.titulo,
			new.autoria,
			new.editora,
			new.categoria,
			new.preco_venda);

				return new;
				
	elsif tg_op = 'DELETE' then
		insert into livraria.log_livro(
			log_livro_data_alteracao,
			log_livro_alteracao,	
			livro_id_old,
			livro_isbn_old,
			livro_titulo_old,
			livro_autoria_old,
			livro_editora_old,
			livro_categoria_old,
			livro_preco_venda_old)
		
		values(
			now(),
			tg_op,
			old.id,
			old.isbn,
			old.titulo,
			old.autoria,
			old.editora,
			old.categoria,
			old.preco_venda);
			
				return new;
	end if;
end;
$$
language 'plpgsql';



create trigger tri_log_livro
after insert or update or delete on "livraria".livro
for each row execute
procedure gera_log_livro();



drop table if exists "livraria".estoque;
create table "livraria".estoque (
id bigint primary key NOT NULL,
id_livro integer not null,
data_aquisicao date not null,
preco_aquisicao decimal(15, 2) not null,
quatidade integer not null,
foreign key (id_livro) references "livaria".livro (id)
);

create sequence estoque_id;


alter table "livraria".estoque alter column id set default nextval('estoque_id');



drop table if exists "livraria".cliente;
create table "livraria".cliente (
	id bigint primary key NOT NULL,
	cpf varchar(15) not null,
	nome varchar(60) not null,
	esdereco varchar(200) not null
);	

create sequence cliente_id;

alter table "livraria".cliente alter column id set default nextval('cliente_id');


drop table if exists "livraria".carrinho;
create table "livraria".carrinho (
	id bigint primary key NOT NULL,
	data date,
	id_pedido integer not null,
	id_cliente integer not null,
	id_exemplares integer not null,
	foreign key (id_cliente) references "livraria".cliente (id)
);

create sequence carrinho_id;

alter table "livraria".carrinho alter column id set default nextval('carrinho_id');


drop table if exists "livraria".pedido;
create table "livraria".pedido (
	id bigint primary key NOT NULL,
	meio_pagamento varchar(20) not null,
	id_carrinho integer not null references "livraria".carrinho(id),
	situacao varchar(20) not null
);

create sequence pedido_id;

alter table "livraria".pedido alter column id set default nextval('pedido_id');

alter table "livraria".carrinho add constraint fk_id_carrinho foreign key (id_pedido) 
	references "livraria".pedido (id);



drop table if exists "livraria".exemplares;
create table "livraria".exemplares (
	id bigint primary key NOT NULL,
	id_livro integer not null references "livraria".livro (id),
	id_carrinho integer not null references "livraria".carrinho(id),
	preco_venda decimal(15, 2) not null,
	quantidade integer not null
);

create sequence exemplares_id;

alter table "livraria".exemplares alter column id set default nextval('exemplares_id');

alter table "livraria".carrinho add constraint fk_id_exemplares foreign key (id_exemplares) 
	references "livraria".exemplares (id);

