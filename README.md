# 📖 Documentação da Arquitetura: GitOps com Terraform, Ansible, OCI e GitHub Actions

Este documento detalha a arquitetura, os serviços, a organização do código e o passo a passo da implementação da nossa esteira de CI/CD (Continuous Integration / Continuous Deployment) para Infraestrutura como Código (IaC). 

O objetivo desta solução é provisionar, configurar e gerenciar recursos na Oracle Cloud Infrastructure (OCI) de forma totalmente automatizada, segura e escalável.

---

## 1. Ferramentas e Serviços Utilizados

*   **Terraform:** Ferramenta principal de orquestração de IaC. Responsável por traduzir nosso código declarativo em chamadas de API para construir a infraestrutura "física/virtual" (servidores, redes, discos).
*   **Ansible:** Ferramenta de Gerenciamento de Configuração. Atua no pós-provisionamento (dentro do sistema operacional) para configurar os recursos, como montar e formatar os discos recém-criados.
*   **Oracle Cloud Infrastructure (OCI):** Nosso provedor de nuvem de destino.
    *   **Compute:** Provisionamento dos servidores (Instâncias).
    *   **Block Storage:** Gerenciamento de discos e volumes.
    *   **Object Storage (S3 Compatible):** Cofre seguro utilizado para armazenar o arquivo de estado do Terraform.
*   **GitHub Actions:** Plataforma de CI/CD que atua como nosso "robô operador". Executa os comandos em ambientes efêmeros.

---

## 2. Os Três Pilares da Solução

Nossa esteira foi construída sobre três pilares fundamentais de engenharia DevOps:

### 🛡️ Segurança: Gestão Efêmera de Chaves Sensíveis
**Conceito:** Nenhuma credencial, OCID privado ou arquivo de acesso à nuvem é exposto no código-fonte.
**Como funciona:** Todas as informações sigilosas estão armazenadas no cofre criptografado do repositório (GitHub Secrets). Para a chave privada da API da OCI, implementamos um mecanismo de injeção efêmera: o GitHub Actions captura o texto da chave do cofre e cria o arquivo localmente dinamicamente dentro da máquina virtual do runner. Assim que o job termina, a máquina virtual é destruída e a chave desaparece completamente, garantindo vazamento zero e proteção total do ambiente.

### ⚙️ Automação: Pipeline CI/CD Unificada
**Conceito:** Eliminar a necessidade de um operador humano rodando comandos no terminal local.
**Como funciona:** O workflow inicializa, valida e aplica as mudanças automaticamente. O pipeline conta com um painel de controle interativo, permitindo que a equipe selecione a ação desejada (`plan`, `apply`, `destroy`) em um menu suspenso diretamente na interface do GitHub. Além de subir a infraestrutura, o Terraform também aciona o Ansible de forma automatizada para configurar o sistema operacional.

### 🧱 Confiabilidade: Estado Remoto Seguro com Workaround S3
**Conceito:** O estado da infraestrutura não fica no computador local. Ele é centralizado na nuvem.
**Como funciona:** Utilizamos o Object Storage da OCI configurado com a API do Amazon S3. Para contornar a incompatibilidade de chunked encoding da AWS (Erro 501 da OCI), injetamos variáveis de ambiente no GitHub Actions forçando um upload limpo e garantindo a integridade do estado na nuvem.

---

## 3. Estrutura de Diretórios e Arquivos do Projeto

O repositório foi organizado utilizando o padrão de Módulos do Terraform, separando responsabilidades lógicas e facilitando a reutilização do código.

### 📂 Diretórios do Repositório
*   `.github/workflows/`: Contém o cérebro da automação. A pipeline do GitHub Actions que define os passos de CI/CD.
*   `ansible/`: Playbook do Ansible. Contém as instruções de pós-provisionamento para formatar e realizar a montagem dos discos no sistema operacional.
*   `terraform/`: O diretório raiz de infraestrutura, subdividido em:
    *   `modules/compute/`: Módulo responsável exclusivamente pela criação de máquinas virtuais (Instâncias).
    *   `modules/storage/`: Módulo responsável pela criação de Block Volumes (discos) e políticas de backup.
    *   `templates/`: Arquivo de template para orientar o Ansible com dados dinâmicos da infraestrutura.

### 📄 Arquivos Principais
*   `main.tf`: O arquivo orquestrador. Ele define o backend e chama os módulos.
*   `provider.tf`: Configura a autenticação com a nuvem da OCI.
*   `variables.tf / outputs.tf`: Declara as variáveis globais e os resultados finais.
*   `ansible_integration.tf`: O arquivo "ponte" que gera o inventário e dispara a execução do Ansible.
*   `.gitignore`: Arquivo de segurança que impede o envio de dados sensíveis ao repositório público.

---

## 4. Passo a Passo da Implementação Realizada

Para replicar ou entender como o ambiente foi inicialmente construído, os seguintes passos técnicos foram executados:

**Passo 1: Preparação na Oracle Cloud (OCI)**
*   **Criação de Usuário de Serviço:** Criado um usuário específico (Service Account) para o GitHub Actions operar na nuvem.
*   **Geração de Credenciais:** Gerada uma chave de API (`.pem` e Fingerprint) para gerenciar recursos, e uma Customer Secret Key (Access e Secret) para comunicação S3.
*   **Criação do Bucket de Estado:** Criado o bucket privado (ex: `ob-tf-state-terraform`) na região de São Paulo para armazenar o `.tfstate`.
*   **Políticas de Acesso (IAM):** Aplicadas políticas de menor privilégio.

**Passo 2: Configuração de Secrets no GitHub**
As variáveis sensíveis foram isoladas do código e cadastradas no repositório (Settings > Secrets and variables > Actions):
*   Credenciais da OCI: `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_PRIVATE_KEY` (texto puro), `OCI_FINGERPRINT`, `OCI_REGION`.
*   Chave de Acesso Remoto: `OCI_SSH_PUBLIC_KEY`.
*   Credenciais S3: `OCI_S3_ACCESS_KEY` e `OCI_S3_SECRET_KEY`.

**Passo 3: Configuração do Backend e Workaround S3**
No arquivo `main.tf`, a comunicação com a OCI foi configurada com flags de compatibilidade, notavelmente `skip_s3_checksum = true` para evitar a recusa do cálculo de checksum da AWS pela OCI.

**Passo 4: Integração do Ansible**
*   Criou-se o playbook `mount_disk.yml`.
*   Utilizou-se o recurso `local_file` para renderizar o template (`ansible_vars.tpl`) com os IPs e IQNs gerados dinamicamente.
*   Utilizou-se o recurso `null_resource` com `local-exec` para disparar a execução via SSH.

**Passo 5: Construção da Pipeline de CI/CD (.yml)**
*   Gatilho manual (`workflow_dispatch`).
*   Criação dinâmica da chave privada no runner.
*   Versão do Terraform rigidamente fixada (`1.14.7`) para evitar quebra de sintaxe.

---

## 5. Resumo do Fluxo de Execução (O Ciclo de Vida)

1.  **Gatilho:** O engenheiro aciona o workflow escolhendo a ação desejada.
2.  **Setup:** O robô monta o ambiente, cria a chave efêmera e inicializa os módulos.
3.  **Provisionamento:** A criação na OCI é orquestrada (máquina, depois storage).
4.  **Configuração Pós-Deploy:** O Ansible é acionado para montar os discos no SO.
5.  **Gravação de Estado:** O processo finaliza salvando a "fotografia" do ambiente remotamente no cofre seguro da OCI.

---

## ⚠️ OBSERVAÇÕES E PONTOS DE ATENÇÃO

Arquiteturas de automação em nuvem exigem cuidados diários. Para manter o ambiente saudável:

1.  **O Perigo da Concorrência (Falta de State Lock):** O Object Storage simulando S3 na OCI não possui State Lock nativo por DynamoDB. Se dois engenheiros rodarem a esteira simultaneamente, o estado corromperá. **Regra:** Comunique a equipe antes de rodar ou configure `concurrency` no GitHub Actions.
2.  **O Calcanhar de Aquiles do Ansible (Acesso SSH):** O robô depende da porta 22 aberta. **Regra:** Garanta que a rede (Security List) permita tráfego SSH da origem do GitHub Actions durante o deploy.
3.  **Versionamento do Bucket de Estado:** O `.tfstate` é o coração do projeto. **Regra:** Mantenha o *Object Versioning* ativo no bucket da OCI para restaurar backups em caso de deleção acidental.
4.  **Manutenção das "Vacinas" (Workarounds):** As travas de versão (`1.14.7`) e variáveis de chunked encoding dependem do cenário atual. **Regra:** Sempre teste atualizações de versão em branches separadas.
5.  **Custo de Esquecimento:** Ambientes sobem rápido, mas custam dinheiro. Considere adicionar um *cronjob* no GitHub Actions para rodar `destroy` automaticamente (ex: sexta-feira à noite) em ambientes de laboratório.

---

## 🚀 Guia de Onboarding (Setup Local)

Este é o guia passo a passo para um novo engenheiro assumir e operar a infraestrutura localmente ou via GitHub.

### 💻 Fase 1: Preparando a sua Máquina
1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/SEU_USUARIO/atlantic-devops-automation.git](https://github.com/SEU_USUARIO/atlantic-devops-automation.git)
    cd atlantic-devops-automation
    
Instale o Terraform: Baixe a versão exata 1.14.7 no site da HashiCorp e valide com terraform version.

Instale o Ansible (Opcional): Apenas se for testar pós-provisionamento local (Linux: sudo apt install ansible).

🔑 Fase 2: Pegando as "Chaves do Castelo" (Na Oracle Cloud)
Anote o OCID do seu Tenant (Tenancy) e o OCID do seu Usuário.

Anote o OCID do Compartimento, da Sub-rede (Subnet) e da Imagem (OS).

Vá em API Keys e gere sua chave (.pem), anotando o Fingerprint.

Vá em Customer Secret Keys e gere sua chave S3 (Access e Secret).

🤐 Fase 3: Configurando o GitHub (O Cofre)
Se você estiver configurando um repositório novo, vá em Settings > Secrets and variables > Actions e cadastre:

OCI_TENANCY_OCID, OCI_USER_OCID, OCI_FINGERPRINT, OCI_REGION

OCI_S3_ACCESS_KEY, OCI_S3_SECRET_KEY

OCI_SSH_PUBLIC_KEY

OCI_PRIVATE_KEY (Cole todo o texto do arquivo .pem baixado).

🏗️ Fase 4: O Arquivo Local .tfvars (Onde os recursos nascem)
Para apontar em qual compartimento ou rede o servidor nascerá, você deve editar ou criar o arquivo terraform.tfvars dentro da pasta terraform/.

🚨 Atenção de Segurança: Para evitar exposição acidental no Git, este arquivo NUNCA deve conter OCIDs de usuário, tenancy ou fingerprints (esses ficam no Actions).

Terraform
# terraform/terraform.tfvars
compartment_id  = "ocid1.compartment.oc1..xxxxxxx"
subnet_id       = "ocid1.subnet.oc1..xxxxxxx"
image_id        = "ocid1.image.oc1..xxxxxxx"
instance_name   = "nome-do-novo-servidor-101"
🚀 Fase 5: Acionando a Automação (O Clique Final)
Tudo configurado!

Abra o seu repositório no navegador e clique na aba Actions.

Selecione o workflow "Terraform GitOps (Controle Manual)".

Clique no botão cinza Run workflow.

Selecione a ação desejada (plan ou apply) e clique no botão verde para rodar.

O robô assumirá o trabalho, provisionará os servidores na Oracle Cloud, rodará o Ansible e guardará o estado no Bucket S3 com total segurança!