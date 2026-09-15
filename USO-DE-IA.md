# Uso de IA Generativa — Grupo 5 (Fedora Server)

## Ferramenta utilizada
Claude (Anthropic), [Claude Sonnet 5 - Claude Sonnet 4.6].

## Onde a IA foi usada

### Script `ssh-sentinel.sh` [Claude Sonnet 5]:

- **Correção da sintaxe e adição de parametros** (Correção do uso do journal,
  e adição da instrução `set -euo pipefail`) o codigo foi revisado pela IA e
  foi apontado erro na sintaxe e falta de alguns parametros.
- **Correções de shellcheck** (SC2155, SC2329) foram sugeridas e aplicadas com
  apoio da IA.
- **Simplificações de sintaxe** (Simplificação de estruturas condicionais longas) foram feitas com apoio da IA
  a pedido do integrante responsável pelo script.

  
- [a função de bloqueio no firewalld foi testada e corrigida
  manualmente após falhas na primeira versão]


### Brute Force [Claude Sonnet 4.6]:

- **Criação de uma wordlist** (geração e filtragem de termos) refinada com
  critérios de tamanho e complexidade para reduzir o tempo de execução e
  focar em padrões de senhas reais.
- **Brute Force Hydra** (atuação da IA como agente autônomo) responsável por
  planejar o ataque, disparar os comandos no terminal e analisar os resultados
  e respostas do servidor em tempo real.

- O ataque foi executado a partir de uma segunda VM, em rede isolada, contra o próprio servidor do grupo — conforme o escopo autorizado pelo trabalho. Nenhum equipamento fora do laboratório do grupo foi alvo.


