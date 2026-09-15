# INSTALL.md — Grupo 5: Fedora Server
## Instalação Segura com LVM sobre LUKS2
 
**Disciplina:** Sistemas Operacionais Linux • Cibersegurança  
**Distribuição:** Fedora Server 44  
**Script do grupo:** `ssh-sentinel.sh` — Detecção de brute force em SSH
 
---
 
## Pré-requisitos
 
| Componente | Especificação |
|------------|---------------|
| Hipervisor | Oracle VirtualBox |
| Firmware | UEFI (obrigatório — nunca BIOS legado) |
| Disco principal | 60 GB (VDI, alocação dinâmica) |
| Disco secundário | 20 GB (adicionado após instalação) |
| Memória RAM | 4 GB (4096 MB) |
| vCPUs | 2 |
| Rede | Adaptador 1: NAT / Adaptador 2: Host-Only |
| ISO | Fedora-Server-dvd-x86_64-44-1.7.iso |
 
### Verificação da ISO antes de instalar
 
Antes de criar a VM, verifique o hash SHA-256 da ISO baixada:
 
```powershell
# No PowerShell (Windows)
Get-FileHash .\Fedora-Server-dvd-x86_64-44-1.7.iso -Algorithm SHA256
```
 
Compare o hash com o valor oficial em: https://fedoraproject.org/server/download
 
---
 
## 1. Criação da VM no VirtualBox
 
1. Abra o VirtualBox → clique em **Novo**
2. Nome: `Fedora-Grupo5` | Tipo: `Linux` | Versão: `Fedora (64-bit)`
3. Memória: **4096 MB** | Processadores: **2**
4. Disco rígido: **Criar novo** → VDI → **60 GB**
5. Clique em **Finalizar**
### Habilitar UEFI (obrigatório)
 
Clique com botão direito na VM → **Configurações → Sistema → Placa-mãe**  
Marque: ✅ **Habilitar EFI (apenas para sistemas operacionais especiais)**
 
### Configurar rede
 
| Adaptador | Tipo | Finalidade |
|-----------|------|------------|
| Adaptador 1 | NAT | Acesso à internet para atualizações |
| Adaptador 2 | Host-Only (192.168.56.0/24) | Acesso SSH local |
 
### Anexar a ISO
 
**Configurações → Armazenamento → Controladora IDE** → selecione a ISO do Fedora Server.
 
---
 
## 2. Instalação do Fedora Server
 
Inicie a VM. Na tela do GRUB, selecione:
 
```
Test this media & install Fedora 44
```
 
> Recomendado para validar a integridade da mídia antes da instalação.
 
### Tela de idioma
- Selecione **English (English)** → Continue
> ⚠️ Manter em inglês evita problemas com nomes de diretórios e comandos.
 
### Installation Summary
 
Configure os seguintes itens:
 
#### Root Account
- ✅ Enable root account
- Defina uma senha forte e anote-a
#### User Creation
- Crie os usuários do grupo com acesso administrativo:
```
Usuário: sshadmin  → Make this user administrator ✅
Usuário: aluno2    → Make this user administrator ✅
Usuário: aluno3    → Make this user administrator ✅
```
 
#### Software Selection
- Selecione: **Fedora Server Edition** (sem GUI)
---
 
## 3. Particionamento — LVM sobre LUKS2
 
Em **Installation Destination**:
- Selecione o disco de **60 GB**
- Storage Configuration: **Custom**
- Clique em **Done**
Na tela de particionamento manual:
- Esquema: **LVM**
- Marque: ✅ **Encrypt my data**
### Diagrama do esquema de particionamento
 
```
sda (60 GB)
├── sda1   /boot/efi   1 GiB    FAT32 (EFI System Partition)
├── sda2   /boot       1 GiB    xfs
└── sda3   ~58 GiB     LUKS2 container
           └── VG: vg_sistema
               ├── lv_root     /          15 GiB   xfs
               ├── lv_var      /var        8 GiB   xfs
               ├── lv_varlog   /var/log    5 GiB   xfs
               ├── lv_vartmp   /var/tmp    3 GiB   xfs
               ├── lv_home     /home      10 GiB   xfs
               ├── lv_tmp      /tmp        3 GiB   xfs
               ├── lv_swap     swap        4 GiB   swap
               └── (livre)                ~9 GiB   reservado para snapshots
```
 
### Criação das partições
 
Crie as partições clicando em **+** na ordem abaixo:
 
| Mount Point | Tamanho | Observação |
|-------------|---------|------------|
| `/boot/efi` | 1 GiB | Criado automaticamente como FAT32 |
| `/boot` | 1 GiB | xfs, fora do LUKS |
| `/` | 15 GiB | xfs |
| `/var` | 8 GiB | xfs |
| `/var/log` | 5 GiB | xfs |
| `/var/tmp` | 3 GiB | xfs |
| `/home` | 10 GiB | xfs |
| `/tmp` | 3 GiB | xfs |
| `swap` | 4 GiB | — |
 
> ⚠️ Deixe ~9 GiB livres no VG — obrigatório para snapshots.
 
### Renomear o Volume Group
 
Clique em qualquer LV → **Modify...** → mude o nome para `vg_sistema` → marque ✅ **Encrypt** → **Save**.
 
### Passphrase do LUKS
 
Ao clicar em **Done**, o Anaconda solicitará a passphrase do LUKS.
 
> ⚠️ **CRÍTICO:** Anote esta passphrase em dois lugares diferentes. Sem ela o sistema não inicializa e não há recuperação possível.
 
Clique em **Accept Changes** para confirmar o particionamento.
 
---
 
## 4. Conclusão da instalação
 
Clique em **Begin Installation** e aguarde a conclusão.  
Ao terminar, clique em **Reboot System**.
 
Na reinicialização, o GRUB solicitará a **passphrase do LUKS** antes de carregar o sistema.
 
---
 
## 5. Pós-instalação
 
### Snapshot 1 — pós-instalação limpa
 
Antes de qualquer configuração, tire um snapshot da VM:
 
**VirtualBox → Máquina → Tirar Snapshot** → Nome: `pos-instalacao-limpa`
 
### Verificações obrigatórias
 
```bash
# Sistema e SELinux
cat /etc/os-release
uname -r
getenforce        # deve retornar: Enforcing
sestatus
 
# Disco, LUKS e LVM
lsblk -f
cryptsetup luksDump /dev/sda3
pvs ; vgs ; lvs
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
cat /etc/fstab
cat /etc/crypttab
```
 
### Criação dos usuários
 
```bash
# Criar usuários do grupo
useradd -m -G wheel sshadmin
passwd sshadmin
 
useradd -m -G wheel aluno2
passwd aluno2
 
useradd -m -G wheel aluno3
passwd aluno3
 
# Criar grupo dedicado para SSH
groupadd sshusers
usermod -aG sshusers sshadmin
usermod -aG sshusers aluno2
usermod -aG sshusers aluno3
```
 
---
 
## 6. Disco secundário de 20 GB — Exercício de ciclo de vida LVM
 
Após a instalação, adicione o disco secundário:
 
**VirtualBox (VM desligada) → Configurações → Armazenamento → Controladora SATA → Adicionar disco → 20 GB**
 
Ligue a VM e execute:
 
```bash
# Verificar se o disco foi reconhecido
lsblk
 
# Criar Physical Volume
pvcreate /dev/sdb
 
# Estender o Volume Group
vgextend LVM-vg_sistema /dev/sdb
 
# Estender o /home em 10 GB
lvextend -L +10G /dev/LVM-vg_sistema/home
 
# Crescer o filesystem a quente (sem desligar)
xfs_growfs /home
 
# Verificar o novo tamanho
lvs
df -h /home
```
 
> O `/home` passa de ~10 GiB para ~20 GiB **sem desligar a VM** — isso demonstra o ciclo de vida do LVM.
 
---
 
## 7. Opções de montagem restritivas
 
Edite o `/etc/fstab` para adicionar opções de segurança:
 
```bash
# Fazer backup antes de editar
cp /etc/fstab /etc/fstab.bak
```
 
| Mount Point | Opções adicionadas | Proteção |
|-------------|-------------------|----------|
| `/tmp` | `nodev,nosuid,noexec` | Impede execução de payload em diretório mundial |
| `/var/tmp` | `nodev,nosuid,noexec` | Idem para diretório temporário de serviços |
| `/var/log` | `nodev,nosuid,noexec` | Impede staging de arquivos na área de log |
| `/home` | `nodev,nosuid` | Impede binários SUID no diretório do usuário |
 
Aplicar sem reiniciar:
 
```bash
mount -o remount /tmp
mount -o remount /var/tmp
mount -o remount /var/log
mount -o remount /home
```
 
Verificar:
 
```bash
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS | grep -E "/home|/tmp|/var/log|/var/tmp"
```
 
---
 
## Conflitos identificados e decisões tomadas
 
O PDF do trabalho alerta: *"Vai dar conflito — e tudo bem. Documentar o conflito e a decisão vale mais nota do que copiar a tabela sem testar."*
 
### Conflito 1 — `noexec` em `/var/tmp` pode quebrar atualizações
 
**Problema:** O `dnf` (gerenciador de pacotes do Fedora) usa `/var/tmp` para descompactar pacotes durante atualizações. Com `noexec`, scripts de pós-instalação que precisam ser executados a partir desse diretório podem falhar.
 
**Teste realizado:**
```bash
dnf check-update
# Retornou atualizações disponíveis normalmente
```
 
**Resultado:** A verificação de atualizações funcionou. Atualizações simples não foram impactadas. Porém atualizações que executam scripts em `/var/tmp` podem falhar.
 
**Decisão:** Mantemos `noexec` em `/var/tmp` pois o ganho de segurança supera o risco. Em caso de falha de atualização, o procedimento é:
 
```bash
# Remover temporariamente o noexec, atualizar e restaurar
mount -o remount,exec /var/tmp
dnf update -y
mount -o remount,noexec /var/tmp
```
 
---
 
### Conflito 2 — `noexec` em `/var/tmp` e `/var` pode quebrar containers
 
**Problema:** Ferramentas como Docker e Podman usam `/var/tmp` e `/var` para armazenar e executar layers de containers. O `noexec` impede a execução de binários nesses diretórios, quebrando o funcionamento de containers.
 
**Decisão:** Como este servidor não executa containers, mantemos as restrições. Em ambientes com containers, a recomendação seria:
 
```bash
# Remover noexec do /var caso containers sejam necessários
# e compensar com outras medidas como SELinux policies
```
 
---
 
### Conflito 3 — `/boot` sem `noexec`
 
**Problema:** O `/boot` não recebe `noexec` porque o GRUB precisa ler e executar o kernel a partir desse diretório durante o boot.
 
**Risco residual:** O `/boot` fica fora do container LUKS — um atacante com acesso físico ao disco poderia manipular o kernel ou o initramfs antes da autenticação LUKS.
 
**Mitigação:** O LUKS protege os dados em repouso. O `/boot` é a superfície de ataque residual conhecida e aceita neste modelo de segurança. A solução completa seria Secure Boot com chaves próprias, o que está fora do escopo deste trabalho.
 
---
 
## 8. Acesso remoto dos integrantes — Tailscale
 
Para acesso remoto sem redirecionamento de porta no roteador:
 
```bash
# Instalar e ativar o Tailscale no Fedora
dnf install -y tailscale
systemctl enable --now tailscaled
tailscale up
```
 
Autentique no link gerado. O IP do Fedora na rede Tailscale é `100.98.214.73`.
 
Os integrantes instalam o Tailscale em seus PCs (tailscale.com/download) e conectam via SSH:
 
```bash
ssh sshadmin@100.98.214.73 -p 2222
```
 
---
 
## 9. Snapshot 2 — pós-configuração inicial
 
Após todas as configurações:
 
**VirtualBox → Máquina → Tirar Snapshot** → Nome: `pos-configuracao-inicial`
 
---
 
## Troubleshooting
 
| Problema | Causa | Solução |
|----------|-------|---------|
| VM boota pela ISO após instalação | ISO ainda anexada | Remover ISO em Configurações → Armazenamento |
| Login incorreto no boot | Confundiu passphrase LUKS com senha do usuário | São senhas diferentes — LUKS é no boot, login é depois |
| SSH recusa conexão | Porta mudada para 2222 | Usar `ssh usuario@ip -p 2222` |
| `nano` não encontrado | Não instalado por padrão no Fedora Server | Usar `vi` ou instalar com `dnf install nano` |
| MCP não conecta após hardening SSH | Porta ou autenticação mudada | Atualizar `fedora_mcp.py` com nova porta e chave |
 
---
 
## Evidências coletadas
 
Todas as evidências estão na pasta `evidencias/` do repositório:
 
- `lsblk-f.txt` — estrutura de discos e LUKS
- `pvs-vgs-lvs.txt` — volumes físicos e lógicos
- `findmnt.txt` — pontos de montagem com opções
- `fstab.txt` — configuração de montagem
- `crypttab.txt` — container LUKS registrado
- `os-release.txt` — versão do sistema
- `sestatus.txt` — SELinux Enforcing
- `sshd-status.txt` — SSH ativo
- prints do particionamento no Anaconda
