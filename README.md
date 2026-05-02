# Automação de Infraestrutura OCI (Terraform + Ansible)

Este repositório contém a automação completa para o provisionamento de infraestrutura na Oracle Cloud Infrastructure (OCI) utilizando **Terraform** e a posterior configuração do sistema operacional (montagem de discos iSCSI) utilizando **Ansible**.

## 🎯 Objetivo da Automação
Provisionar uma instância de computação na OCI (VM.Standard.E4.Flex), atachar múltiplos discos em bloco (Block Volumes) via iSCSI, aplicar políticas automáticas de backup e realizar a inicialização, formatação (ext4) e montagem desses discos diretamente no Linux, garantindo as permissões corretas para os usuários.

## 📂 Estrutura do Repositório

O projeto segue as melhores práticas de separação de responsabilidades (Infraestrutura como Código vs. Gerenciamento de Configuração):
```text
atlantic-devops-automation/
├── .gitignore                 # Arquivos sensíveis e de estado ignorados pelo Git
├── README.md                  # Documentação do projeto
├── terraform/                 # Todo o código de provisionamento (IaC)
│   ├── main.tf                # Recursos: Instância, Discos e Attachments
│   ├── variables.tf           # Declaração das variáveis do Terraform
│   ├── outputs.tf             # Outputs exibidos no terminal
│   ├── provider.tf            # Configuração do Provider OCI
│   ├── ansible_integration.tf # Geração dinâmica do arquivo de variáveis do Ansible
│   └── templates/
│       └── ansible_vars.tpl   # Molde (template) para integração Terraform -> Ansible
└── ansible/                   # Todo o código de configuração do S.O.
    └── mount_disk.yml         # Playbook para formatação e montagem dos discos iSCSI
🚀 Como Executar
Pré-requisitos
•	Terraform (>= 1.0.0) instalado localmente.
•	Ansible instalado localmente.
•	Credenciais da OCI configuradas (Tenancy OCID, User OCID, Fingerprint e Private Key).
Passo 1: Provisionar a Infraestrutura (Terraform)
Abra o terminal na raiz do repositório e execute:
Bash
# 1. Entre no diretório do Terraform
cd terraform/

# 2. Inicialize o provider e os módulos
terraform init

# 3. Valide o código (Opcional, mas recomendado)
terraform validate

# 4. Aplique a infraestrutura
terraform apply -auto-approve
Nota: Ao final do apply, o Terraform irá criar dinamicamente o arquivo iscsi_vars.yml e a chave SSH privada .pem dentro da pasta terraform/.
Passo 2: Configurar os Discos (Ansible)
Volte para a raiz do repositório e execute o playbook do Ansible, utilizando o IP privado da instância gerado no output do passo anterior:
Bash
# 1. Volte para a raiz do projeto
cd ..

# 2. Execute o Playbook (Substitua <IP_DA_INSTANCIA> pelo IP gerado no Terraform)
ansible-playbook -i "<IP_DA_INSTANCIA>," -u ubuntu --private-key terraform/adalive-tst.pem ansible/mount_disk.yml
O que o Ansible fará automaticamente:
1.	Atualizará o S.O. (apt update e upgrade).
2.	Instalará o serviço open-iscsi.
3.	Fará o discovery e o login nos targets iSCSI de todos os discos mapeados.
4.	Criará as tabelas de partição e formatará em ext4.
5.	Criará os diretórios de montagem (/home/ubuntu/AdAlive-Apps e /u01).
6.	Inserirá as regras no /etc/fstab com a diretiva _netdev (garantindo reboots seguros).
7.	Ajustará o owner/group das pastas montadas para o usuário ubuntu.
