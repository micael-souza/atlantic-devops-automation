Aqui está o código Markdown atualizado para o seu README.md. Ele agora reflete a estrutura modular avançada e destaca a nova esteira de Integração Contínua (CI) com o GitHub Actions que você acabou de implementar.

Você pode copiar o bloco abaixo e substituir todo o conteúdo atual do seu arquivo README.md:

Markdown
# ☁️ Automação de Infraestrutura OCI (Terraform Modular + Ansible + CI/CD)

Este repositório contém uma solução corporativa de ponta a ponta para o provisionamento automatizado de infraestrutura na Oracle Cloud Infrastructure (OCI) e configuração de sistema operacional. 

O projeto adota uma arquitetura modular, garantindo escalabilidade, segurança e reaproveitamento de código, seguindo as melhores práticas de Engenharia de Plataforma (Platform Engineering), DevOps e Integração Contínua.

## 🎯 Escopo do Projeto

A esteira executa três funções principais de forma totalmente automatizada e desacoplada:
1. **Integração Contínua (GitHub Actions):** Valida a formatação e a sintaxe do código Terraform automaticamente a cada *Push* ou *Pull Request*, garantindo a qualidade do código antes do deploy.
2. **Infraestrutura como Código (Terraform):** Provisiona instâncias computacionais (Compute) e volumes de bloco (Storage), aplicando políticas automáticas de backup e conectando-os via protocolo iSCSI.
3. **Gerenciamento de Configuração (Ansible):** Conecta via SSH, atualiza o S.O., instala dependências, descobre os *targets* iSCSI, cria partições, formata (ext4) e monta os volumes de forma persistente (fstab) com governança de permissões.

## 📂 Arquitetura de Diretórios

O código foi refatorado em **Módulos** e conta com uma esteira de automação:
```text
atlantic-devops-automation/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml   # 🤖 Pipeline de CI (GitHub Actions)
├── .gitignore                 # Proteção de arquivos sensíveis (estado e chaves)
├── README.md                  # Documentação principal
├── terraform/                 # ☁️ Root module (Ponto de entrada do provisionamento)
│   ├── main.tf                # Chamada dos módulos (Compute e Storage)
│   ├── variables.tf           # Definição das variáveis de ambiente
│   ├── outputs.tf             # Saídas no console
│   ├── provider.tf            # Configuração de conexão com a OCI
│   ├── ansible_integration.tf # Geração dinâmica de variáveis (Handover para o Ansible)
│   ├── templates/             
│   │   └── ansible_vars.tpl   # Template gerador do iscsi_vars.yml
│   └── modules/               # 📦 Módulos reutilizáveis
│       ├── compute/           # Lógica da Instância e Rede
│       └── storage/           # Lógica dos Discos em Bloco (Block Volumes)
└── ansible/                   
    └── mount_disk.yml         # 🐧 Playbook de montagem idempotente
🛠️ Pré-requisitos
Para executar este projeto, você precisará ter instalado na sua máquina local:

Terraform (v1.0.0 ou superior)

Ansible (v2.9 ou superior)

Credenciais ativas da Oracle Cloud (Tenancy OCID, User OCID, Fingerprint e Chave Privada API).

🚀 Como Executar (Passo a Passo)
Passo 1: Subir a Infraestrutura (Terraform)
Abra o terminal na raiz do repositório, acesse a pasta do Terraform e inicialize os módulos:

Bash
# 1. Acesse o diretório
cd terraform/

# 2. Baixe os providers e inicialize os módulos locais
terraform init

# 3. Provisione os recursos (Aprovação automática)
terraform apply -auto-approve
💡 Nota: Após a execução, o Terraform gerará um IP Privado, baixará a chave SSH (.pem) na pasta do Terraform e criará dinamicamente o arquivo de integração com o Ansible (iscsi_vars.yml).

Passo 2: Configurar o S.O. e Discos (Ansible)
Volte para a raiz do repositório e chame o playbook do Ansible, utilizando os dados gerados no Passo 1:

Bash
# 1. Volte para a raiz do projeto
cd ..

# 2. Execute o playbook de montagem
# Substitua <IP_GERADO> e <NOME_DA_CHAVE>.pem pelos valores gerados pelo Terraform
ansible-playbook -i "<IP_GERADO>," -u ubuntu --private-key terraform/<NOME_DA_CHAVE>.pem ansible/mount_disk.yml
📈 Escalabilidade: Como adicionar mais discos?
Graças à arquitetura modular, adicionar novos discos à instância é extremamente simples. Não é necessário reescrever lógicas de iSCSI ou scripts no S.O.

No Terraform (terraform/main.tf): Adicione uma nova chamada ao módulo de storage:

Terraform
module "novo_disco" {
  source              = "./modules/storage"
  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "nome-do-seu-novo-disco"
  size_in_gbs         = 50
  instance_id         = module.servidor.instance_id
  backup_policy_id    = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}
Integração (terraform/ansible_integration.tf): Adicione as variáveis do disco exportadas pelo módulo.

No Ansible (ansible/mount_disk.yml): Adicione um novo item na lista de variáveis discos_oci. O Ansible fará o loop e montará o novo disco automaticamente na próxima execução.