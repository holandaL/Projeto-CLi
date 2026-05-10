# Agenda CLI em Elixir

Projeto prático individual da disciplina **T300 - Programação Funcional**.

A aplicação é uma agenda de contatos pessoais executada via linha de comando, desenvolvida em Elixir com Mix, utilizando programação funcional, pattern matching, pipe operator, recursão de cauda e persistência em JSON.

## Tecnologias utilizadas

- Elixir
- Mix
- Jason para serialização JSON

## Instalação

Clone o repositório:

```bash
git clone LINK_DO_SEU_REPOSITORIO
cd agenda_cli
```

Instale as dependências:

```bash
mix deps.get
```

Execute a aplicação:

```bash
mix run
```

## Comandos disponíveis

### Adicionar contato

```bash
add --name Ana Lima --company Acme --phone 85912345678 --email ana.lima@acme.com
```

### Editar contato

```bash
edit 1713531600000 --phone 85912341234
edit 1713531600000 --email novo.email@acme.com
edit 1713531600000 --name Ana Silva --company Acme LTDA
```

### Remover contato

```bash
del 1713531600000
```

### Exibir contato específico

```bash
show 1713531600000
```

### Listar contatos

```bash
list
```

### Buscar contatos

A busca é parcial e não diferencia letras maiúsculas de minúsculas.

```bash
search --name ana
search --phone 85
search --email gmail
```

### Criar base de teste

```bash
test
```

### Encerrar

```bash
exit
```

## Organização dos módulos

- `AgendaCli`: ponto de entrada da aplicação, loop recursivo, leitura dos comandos e parsing das flags.
- `AgendaCli.Contacts`: funções puras para adicionar, editar, remover, buscar e listar contatos.
- `AgendaCli.Store`: leitura e escrita do arquivo `contacts.json` usando Jason.

## Persistência

Os contatos são salvos no arquivo `contacts.json`, criado automaticamente durante a execução. Esse arquivo não deve ser enviado para o GitHub, pois está listado no `.gitignore`.

## Observação sobre uso de IA

Este projeto foi desenvolvido com apoio de Inteligência Artificial para auxiliar na estruturação do código, organização dos módulos, criação do README e revisão dos requisitos da atividade. O aluno deve compreender e conseguir explicar todos os trechos do código durante a apresentação.
