teste git comandos

git status = verificar status dos arquivos que foram add no repositorio;

git log = listas as ultimas atualizações gravadas;

git add = adicionar arquivos ao repositório local;

git commit = gravar as alterações efetuadas nos aruqivos do repositorio local;

git push = levar as alterações local para o repositorio remoto.

-- novos comandos --

git clone git@github.com:douglasribeiro687/rep-teste-git.git = baixar arquivos de um repositorio remoto

git pull = sincronizar o projeto do repositorio remoto no repositorio local

git checkout = voltar uma versão do repositorio ou voltar apenas um arquivo com base nas gravações feitas

git checkout HEAD = voltar uma alteração após o git add ( sem commit )

git chechout HEAD~1 = voltar a alteração do arquivo em 1 commit ( sem o comando push ) - apenas local

git checkout HEAD~1 hard = voltar a altecao do arquivo em 1 commit - deleta todos os logs realizados após esse commit 

-- agora vamos falar de conflitos no mesmo arquivo --