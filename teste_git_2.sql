-- teste git comandos --

git remote add <url do repositorio remoto> = criar um repositorio remoto.

git status = verificar status dos arquivos que foram add no repositorio;

git log = listas as ultimas atualizações gravadas;

git add <nome do arquivo> = adicionar arquivos ao repositório local;

git commit = gravar as alterações efetuadas nos aruqivos do repositorio local;

git push = levar as alterações local para o repositorio remoto.

Link para criar a chave SSH e não precisar de usuário e senha toda hora. 
https://help.github.com/en/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

Paste the text below, substituting in your GitHub email address.
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

-- novos comandos --

git clone git@github.com:douglasribeiro687/rep-teste-git.git = baixar arquivos de um repositorio remoto

git pull = sincronizar o projeto do repositorio remoto no repositorio local

git checkout = voltar uma versão do repositorio ou voltar apenas um arquivo com base nas gravações feitas

git checkout HEAD = voltar uma alteração após o git add ( sem commit )

git chechout HEAD~1 = voltar a alteração do arquivo em 1 commit ( sem o comando push ) - apenas local

git checkout HEAD~1 hard = voltar a altecao do arquivo em 1 commit - deleta todos os logs realizados após esse commit 

-- novos comandos --

git branch = criar uma nova estande para gravar alterações.

git branch -d = deletar uma estande existente.

git checkout <nome da branch> = apontar para o git que está é a principal.

git checkout -b <nome da branch> = criar uma nova branch e faz o checkout auto.

git checkout <nome do arquivo> = fazer checkout do arquivo em especial - antes de gravar na stage.

-- proxima aula é sobre branching --

git push -u origin branch-dev-01 = criar a nova branc no repositorio remoto

git merge <nome da branch> = comparar a versão master com a branch criada.

git fetch = baixar as atualizações do git remoto mais não atualiza o repositório.

-- implementar os commits de outros branchs a master ---

git rebase <branch master> = juntar os commits da branch atual dentro da master.

git rebase --continue = confirmar o rebase na brench master

git rebase --abort = cancelar a tentativa de rebase na branch master

teste com o comando "git rebase <branch>".

-- aula de tag ---

git tag <nome da tag= criando uma versão estatica do repositorio que não podera ser alterada - controle de versão.

git push origin <nome da tag> = enviar a tag para o git remoto

git checkout <nome da tag> = baixar essa tag do repositorio


-- alguns programas ou plugins pra uso do git --

Egit = eclipse - boa utilização

GitEye = GUI fácil de usar, mesma IDE do eclipse

-- Seguindo o Github nas redes --

Fork = realizar uma copia de qualquer repositorio no GitHub e trazer para o seu uso.

Issues = organizar tarefas a serem feitas dentro do projeto no repositorio. (não é do git e sim da ferramenta remota GitHub).

No git commit vc deve apontar a Issues se desejar fechar no Github - git commit -m "Bug corrigido. Closes #001"

Pull Request = é quando solicitamos que nossas alterações sejam lançadas em alguma 
branch local ou um repositorio que sofreu um Fork.

Guia de introdução ao fluxo de alteração em repositorios no GitHub
https://guides.github.com/introduction/flow/

-- EXERCICIO FINAL DO CURSO Git e GitHub --

Fazer um fork do repositorio github.com/BrOrlandi/GitTrainingWall

Clonar o projeto com git clone

Gerar uma branch para realizar a alteração.

Alteração/inclusão da nova html com o novo usuario.

-- Pull Request --

git fetch origin pull/ID/head:branch

