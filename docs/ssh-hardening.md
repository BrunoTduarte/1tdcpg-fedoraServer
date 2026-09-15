# SSH Endurecido — Grupo 5 (Fedora Server)
Responsável: Heitor

## Usuários e chaves
- Cada integrante (heitor, pascoal, bruno) tem usuário nominal próprio na VM
- Autenticação exclusivamente por chave ed25519 (sem passphrase)
- Chaves cadastradas em ~/.ssh/authorized_keys de cada usuário
- Todos os usuários pertencem ao grupo dedicado `ssh-users`

## Configuração aplicada em /etc/ssh/sshd_config
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
AllowGroups ssh-users
Port 2222
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
Banner /etc/issue.net


## SELinux
Porta 2222 registrada com o contexto ssh_port_t:
```bash
sudo semanage port -a -t ssh_port_t -p tcp 2222
```

## Política de criptografia
```bash
sudo update-crypto-policies --set DEFAULT
```

## Banner legal (/etc/issue.net)

AVISO: Acesso restrito a usuários autorizados do laboratório Grupo 5.
Todas as sessões são registradas. Uso não autorizado é crime (Art. 154-A CP).



## Firewalld
```bash
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-rich-rule='rule port port="2222" protocol="tcp" accept limit value="10/m"'
sudo firewall-cmd --reload
```

## Regra de ouro seguida
Antes de reiniciar o sshd, validamos a sintaxe (`sshd -t`) e mantivemos uma
sessão SSH aberta em paralelo, testando a nova configuração numa segunda
sessão antes de fechar a original.

## Evidências coletadas (pasta evidencias/ssh/)
- `evidencia-sshd-T.txt`: configuração efetiva do sshd
- `evidencia-status-sshd.txt`: status do serviço
- `evidencia-firewall.txt`: regras do firewalld
- `evidencia-portas.txt`: portas em escuta (ss -tulpn)
- `evidencia-selinux-porta.txt`: contexto SELinux da porta 2222
- `evidencia-journal-ssh.txt`: log com tentativa bloqueada (usuário sem chave)
- `evidencia-journal-ssh-final.txt`: log com os 3 acessos por chave (heitor, pascoal, bruno)

## Reversibilidade
```bash
# reverter sshd_config
sudo cp /etc/ssh/sshd_config.bak.<data> /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl restart sshd

# reverter porta no SELinux
sudo semanage port -d -t ssh_port_t -p tcp 2222

# reverter firewall
sudo firewall-cmd --permanent --remove-port=2222/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```
