# Cinco Perguntas para a Turma — Grupo 5 (Fedora Server)

Formato: 3 de múltipla escolha + 2 dissertativas curtas (até 3 linhas).
Toda pergunta é respondível apenas com o conteúdo apresentado por este grupo.
Gabarito comentado a ser entregue ao professor com 48h de antecedência.

---

## Questão 1 (múltipla escolha)

**No ecossistema Red Hat, qual é a posição do Fedora Linux em relação ao RHEL?**

a) O Fedora é um clone binário do RHEL, lançado depois dele, sem relação de dependência de código
b) O Fedora é o upstream mais próximo do usuário final: recursos são testados nele primeiro e, depois, chegam ao RHEL via CentOS Stream
c) O RHEL é que serve de upstream para o Fedora — a Red Hat testa recursos no RHEL antes de portá-los para o Fedora
d) Fedora e RHEL são projetos totalmente independentes, mantidos por empresas diferentes, sem nenhuma relação técnica

**Resposta correta:** b

**Comentário do gabarito:** O Fedora Project reúne código de dezenas de projetos upstream (kernel, GNOME, systemd etc.) para montar o Fedora Linux; periodicamente, a Red Hat parte de um lançamento do Fedora para basear uma versão do RHEL — hoje com o CentOS Stream como estágio intermediário de estabilização entre os dois. A alternativa (a) descreve na verdade os clones binários como Rocky/AlmaLinux, não o Fedora; (c) inverte o sentido real do fluxo; (d) ignora que a própria Red Hat patrocina e mantém o projeto Fedora.

---

## Questão 2 (múltipla escolha)

**Por que as partições `/boot/efi` e `/boot` ficam fora do container LUKS no esquema de particionamento deste trabalho?**

a) Porque partições pequenas (abaixo de 2 GiB) não podem ser criptografadas pelo cryptsetup
b) Porque o GRUB precisa conseguir ler o kernel e a initramfs antes de existir qualquer chave de descriptografia disponível
c) Porque o firmware UEFI bloqueia automaticamente a criptografia de qualquer partição de boot
d) Porque deixar o `/boot` fora do LUKS elimina totalmente o risco de acesso físico ao disco

**Resposta correta:** b

**Comentário do gabarito:** É o próprio GRUB (ou um estágio anterior a ele) que solicita a passphrase do LUKS para desbloquear o restante do disco — por isso ele precisa acessar o kernel antes que qualquer chave exista. Isso deixa um risco residual conhecido: quem tiver acesso físico ao disco pode ler ou adulterar o conteúdo de `/boot`. As alternativas (a) e (c) são tecnicamente falsas, e (d) contradiz exatamente o risco residual que o grupo apresentou.

---

## Questão 3 (múltipla escolha)

**No script `ssh-sentinel.sh`, qual é a função da allowlist (lista de exceções)?**

a) Listar os usuários que têm permissão para usar senha em vez de chave pública
b) Listar os IPs que nunca devem ser bloqueados pelo script, mesmo ultrapassando o limiar de falhas configurado
c) Listar os algoritmos de criptografia permitidos pela política do `update-crypto-policies`
d) Listar as portas que o firewalld deve manter sempre abertas, independentemente do script

**Resposta correta:** b

**Comentário do gabarito:** A allowlist existe para impedir que o próprio script bloqueie a rede de gerência da VM ou o IP do administrador que está testando — sem ela, o `ssh-sentinel.sh` poderia causar a negação de serviço que deveria prevenir. As demais alternativas confundem esse conceito com outros mecanismos apresentados (autenticação por chave, política de criptografia e regras do firewalld), que são independentes da allowlist do script.

---

## Questão 4 (dissertativa curta — até 3 linhas)

**O enunciado do trabalho aplica um desconto de 10 pontos caso o SELinux esteja desligado, o maior desconto pontual da rubrica. Por que o SELinux é tratado como um controle tão central, mesmo com o disco já protegido por LUKS e o SSH já endurecido?**

**Resposta esperada (gabarito comentado):** Porque LUKS e SSH endurecido protegem, respectivamente, os dados em repouso e o acesso remoto — mas nenhum dos dois controla o que um processo já em execução (mesmo como root) pode fazer dentro do sistema ligado. O SELinux aplica controle de acesso obrigatório baseado em rótulos, restringindo processos mesmo com privilégio elevado, cobrindo exatamente a lacuna que LUKS (que só protege com a máquina desligada) e o SSH (que só controla a porta de entrada) deixam aberta.

---

## Questão 5 (dissertativa curta — até 3 linhas)

**O grupo documentou um conflito entre a opção `noexec` em `/var/tmp` e o funcionamento do `dnf`. Explique, em poucas linhas, qual foi o conflito e a decisão tomada pelo grupo.**

**Resposta esperada (gabarito comentado):** O `dnf` usa `/var/tmp` para descompactar pacotes durante atualizações, e scripts pós-instalação que precisem ser executados a partir desse diretório podem falhar com `noexec` ativo. O grupo testou com `dnf check-update`, que funcionou normalmente, e decidiu manter `noexec` por padrão — já que o ganho de segurança supera o risco — reservando a remontagem temporária com `exec` apenas para o caso de uma atualização específica realmente falhar por esse motivo.

---

**Uso em slides:** cada questão ocupa um slide com a pergunta e as alternativas (ou o enunciado dissertativo); o slide seguinte traz a resposta correta e o comentário do gabarito.
