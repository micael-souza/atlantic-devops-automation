# 🚀 Automação de Infraestrutura GitOps: Terraform, Ansible e OCI

Este repositório contém a arquitetura e o código-fonte da esteira de CI/CD (Continuous Integration / Continuous Deployment) para Infraestrutura como Código (IaC) da **Atlantic Solutions**. 

O objetivo desta solução é provisionar, configurar e gerenciar recursos na Oracle Cloud Infrastructure (OCI) de forma totalmente automatizada, segura e escalável, utilizando o modelo GitOps.

---

## 🛠️ 1. Ferramentas e Serviços Utilizados

*   **[Terraform](https://www.terraform.io/) (v1.14.7):** Ferramenta principal de orquestração de IaC. Traduz o código declarativo em chamadas de API para construir a infraestrutura física/virtual (servidores, redes, discos).
*   **[Ansible](https://www.ansible.com/):** Ferramenta de Gerenciamento de Configuração. Atua no pós-provisionamento para configurar os recursos operacionais (ex: formatação e montagem de discos).
*   **[Oracle Cloud Infrastructure (OCI)](https://www.oracle.com/cloud/):** Provedor de nuvem de destino.
    *   *Compute:* Provisionamento dos servidores (Instâncias).
    *   *Block Storage:* Gerenciamento de discos e volumes.
    *   *Object Storage (S3 Compatible):* Cofre seguro utilizado para armazenar o arquivo de estado (`.tfstate`).
*   **[GitHub Actions](https://github.com/features/actions):** Plataforma de CI/CD que atua como nosso "robô operador", executando os comandos em ambientes efêmeros.

---

## 🏛️ 2. Os Três Pilares da Solução

### 🛡️ Segurança: Gestão Efêmera de Chaves Sensíveis
Nenhuma credencial, OCID privado ou arquivo de acesso à nuvem é exposto no código-fonte. 
Todas as informações sigilosas estão no cofre criptografado (**GitHub Secrets**). O GitHub Actions captura o texto da chave privada da API da OCI e cria um arquivo `.pem` dinamicamente dentro do *runner*. Ao fim do job, a máquina virtual é destruída e a chave desaparece (vazamento zero).

### ⚙️ Automação: Pipeline CI/CD Unificada
Eliminamos a necessidade de execução local. O workflow inicializa, valida e aplica as mudanças automaticamente via GitHub Actions. O pipeline possui um painel interativo (`workflow_dispatch`), permitindo selecionar a ação (`plan`, `apply`, `destroy`) em um menu suspenso. O Terraform também aciona o Ansible automaticamente via `local-exec` pós-deploy.

### 🧱 Confiabilidade: Estado Remoto Seguro (Workaround S3)
O estado (`.tfstate`) é centralizado na nuvem utilizando o Object Storage da OCI configurado com a API do Amazon S3. Para contornar a incompatibilidade de *chunked encoding* da AWS (Erro 501 da OCI), injetamos as variáveis `AWS_REQUEST_CHECKSUM_CALCULATION` e `AWS_RESPONSE_CHECKSUM_VALIDATION` no GitHub Actions, garantindo um upload limpo.

---

## 📂 3. Estrutura de Diretórios e Arquivos

O projeto utiliza o padrão de **Módulos do Terraform** para separar responsabilidades lógicas.
```text
📦 atlantic-devops-automation
├── 📂 .github/workflows/
│   └── 📄 terraform-ci.yml        # Cérebro da automação (Pipeline principal)
├── 📂 ansible/
│   └── 📄 mount_disk.yml          # Playbook de pós-provisionamento de discos
├── 📂 terraform/
│   ├── 📂 modules/
│   │   ├── 📂 compute/            # Módulo de criação de Instâncias (VMs)
│   │   └── 📂 storage/            # Módulo de criação de Block Volumes
│   ├── 📂 templates/
│   │   └── 📄 ansible_vars.tpl    # Template para injetar IPs e vars no Ansible
│   ├── 📄 main.tf                 # Orquestrador, define o backend (S3) e chama módulos
│   ├── 📄 provider.tf             # Configuração de autenticação com a OCI
│   ├── 📄 variables.tf            # Declaração de variáveis globais
│   ├── 📄 outputs.tf              # Exibição de resultados no terminal
│   └── 📄 ansible_integration.tf  # Ponte Terraform -> Ansible (Inventário e execução)
├── 📄 .gitignore                  # Proteção de arquivos sensíveis e de cache
└── 📄 README.md                   # Esta documentação
🚀 4. Passo a Passo da Implementação Realizada
Para replicar ou entender como o ambiente foi inicialmente construído:

Preparação na OCI:

Criação de Usuário de Serviço (Service Account).

Geração de credenciais de API (.pem/Fingerprint) e Customer Secret Keys (S3).

Criação do bucket privado e aplicação de políticas IAM de menor privilégio.

Configuração de Secrets no GitHub:

Cadastro de variáveis sensíveis da OCI (TENANCY_OCID, USER_OCID, PRIVATE_KEY, REGION).

Cadastro das variáveis da infra (COMPARTMENT_OCID, SUBNET_ID, IMAGE_ID).

Cadastro das credenciais S3 (S3_ACCESS_KEY, S3_SECRET_KEY).

Configuração do Backend e Workaround S3 (main.tf):

Configuração do bloco com skip_requesting_account_id = true e skip_s3_checksum = true para compatibilidade com o Storage da Oracle.

Integração do Ansible (ansible_integration.tf):

Uso do local_file para gerar o inventário dinâmico a partir do template (ansible_vars.tpl).

Disparo via null_resource com local-exec via SSH após o provisionamento.

Construção da Pipeline (terraform-ci.yml):

Gatilho manual configurado com workflow_dispatch.

Injeção segura de chaves efêmeras via shell (chmod 600).

Versão do Terraform cravada na pipeline para evitar quebra de sintaxe.

🔄 5. Fluxo de Execução (Ciclo de Vida)
Gatilho: O engenheiro aciona o workflow no GitHub Actions escolhendo a ação.

Setup: O runner monta o ambiente, injeta as chaves efêmeras do cofre e inicializa os módulos (init).

Provisionamento: O Terraform orquestra a criação na OCI (Computação e depois Storage).

Configuração Pós-Deploy: O IP da nova máquina é lido e o Ansible é acionado silenciosamente para montar os discos.

Gravação de Estado: O processo é finalizado salvando a "fotografia" do ambiente remotamente no cofre seguro.