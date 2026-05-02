# O CODIGO CRIA UMA MÁQUINA VIRTUAL + DISCOS NA OCI E MONTA O DISCO COM O ANSIBLE

# PRÉ REQUISITOS:
## NECESSÁRIO PARA TER O TERRAFORM E O ANSIBLE INSTALADOS

# PASSO A PASSO PARA A EXECUÇÃO:

## Entra na pasta do terraform e roda o apply

### $ cd terraform
### $ terraform apply -auto-approve

## Volta para a raiz do repositório
### $ cd ..

## Executa o playbook passando o caminho da pasta ansible e usando a chave na pasta terraform
### $ ansible-playbook -i "<ip_gerado_do_servidor>," -u ubuntu --private-key terraform/<nome_da_chave> ansible/mount_disk.yml