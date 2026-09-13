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
 
