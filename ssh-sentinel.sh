#!/bin/bash

#Date           :14/09/2026
#Author         :Matheus Pascoal
#Description    :Detector de tentativa de brute force no ssh

set -euo pipefail

NOME="$(basename "$0")"
readonly NOME
readonly LOG="/var/log/ssh-sentinel.log"
readonly EXCECOES="/etc/ssh-sentinel/excecoes.conf"
readonly ZONA="public"

LIMIAR=5
TTL="1h"
JANELA="1 hour ago"
DRYRUN=0
TMP=""

# shellcheck disable=SC2329
limpar() {
    if [[ -n "${TMP}" ]]; then
        if [[ -d "${TMP}" ]]; then
            rm -rf -- "${TMP}"
        fi
    fi
}
trap limpar EXIT INT TERM

log() {
    local nivel="$1"
    shift
    local data_hora
    data_hora="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${data_hora}] [${nivel}] $*" | tee -a "${LOG}"
}

mostrar_ajuda() {
    cat <<EOF
Uso: ${NOME} [OPÇÕES]

Detecta tentativas de força bruta em SSH via journald e bloqueia
os IPs ofensores no firewalld por um período determinado.

Opções:
  -l, --limiar N        Falhas para considerar brute force (padrão: ${LIMIAR})
  -t, --ttl DURACAO     Duração do bloqueio, ex: 30m, 1h (padrão: ${TTL})
  -j, --janela TEXTO    Janela de tempo do journalctl (padrão: "${JANELA}")
  -n, --dry-run         Não aplica bloqueios, apenas simula
  -h, --help            Mostra esta ajuda e sai

Códigos de saída:
  0  sucesso, nenhum achado
  1  sucesso, achados encontrados
  2  erro de uso
  3  dependência ausente ou privilégio insuficiente
EOF
}

parse_argumentos() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                mostrar_ajuda
                exit 0
                ;;
            --limiar|-l)
                if ! [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    log "ERROR" "--limiar exige um número. Recebido: '${2:-}'"
                    exit 2
                fi
                LIMIAR="$2"
                shift 2
                ;;
            --ttl|-t)
                if ! [[ "${2:-}" =~ ^[0-9]+[smhd]?$ ]]; then
                    log "ERROR" "--ttl inválido: '${2:-}'"
                    exit 2
                fi
                TTL="$2"
                shift 2
                ;;
            --janela|-j)
                if [[ -z "${2:-}" ]]; then
                    log "ERROR" "--janela exige um valor."
                    exit 2
                fi
                JANELA="$2"
                shift 2
                ;;
            --dry-run|-n)
                DRYRUN=1
                shift
                ;;
            *)
                log "ERROR" "Parâmetro desconhecido: $1"
                mostrar_ajuda
                exit 2
                ;;
        esac
    done
}

verificar_privilegio() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERRO: este script precisa ser executado como root." >&2
        exit 3
    fi
}

verificar_dependencias() {
    local lista="journalctl firewall-cmd awk grep sort uniq date mktemp"
    local dep
    for dep in ${lista}; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            echo "ERRO: dependência ausente: ${dep}" >&2
            exit 3
        fi
    done
}

carregar_excecoes() {
    if [[ ! -f "${EXCECOES}" ]]; then
        mkdir -p "$(dirname "${EXCECOES}")"
        : > "${EXCECOES}"
        chmod 640 "${EXCECOES}"
    fi
    grep -Ev '^[[:space:]]*(#|$)' "${EXCECOES}"
}

extrair_falhas_por_ip() {
    journalctl -u sshd --since "${JANELA}" --no-pager 2>/dev/null > "${TMP}/journal.txt"
    grep -E "Failed password|authentication failure|Invalid user" "${TMP}/journal.txt" > "${TMP}/linhas_falha.txt" || true
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "${TMP}/linhas_falha.txt" > "${TMP}/ips.txt" || true
    sort "${TMP}/ips.txt" | uniq -c | sort -rn
}

extrair_usuarios_visados() {
    grep -oE "Failed password for (invalid user )?[a-zA-Z0-9_.-]+" "${TMP}/linhas_falha.txt" > "${TMP}/usuarios.txt" || true
    awk '{print $NF}' "${TMP}/usuarios.txt" > "${TMP}/nomes.txt"
    sort "${TMP}/nomes.txt" | uniq -c | sort -rn
}

ip_ja_bloqueado() {
    local ip="$1"
    firewall-cmd --zone="${ZONA}" --list-rich-rules 2>/dev/null | grep -qF "address=\"${ip}\""
}

bloquear_ip() {
    local ip="$1"

    if [[ "${DRYRUN}" -eq 1 ]]; then
        log "INFO" "[DRY-RUN] Bloquearia ${ip} por ${TTL}"
        return
    fi

    if ip_ja_bloqueado "${ip}"; then
        log "INFO" "IP ${ip} já possui regra ativa. Nada a fazer."
        return
    fi

    if firewall-cmd --zone="${ZONA}" --add-rich-rule="rule family='ipv4' source address='${ip}' reject" --timeout="${TTL}" >/dev/null 2>&1; then
        log "WARN" "IP bloqueado: ${ip} (TTL=${TTL})"
    else
        log "ERROR" "Falha ao bloquear ${ip} no firewalld."
    fi
}

gerar_relatorio() {
    local ips="$1"
    local usuarios="$2"
    local data_hora
    data_hora="$(date '+%Y-%m-%d %H:%M:%S')"

    {
        echo "===== RELATÓRIO SSH-SENTINEL - ${data_hora} ====="
        echo "Janela: ${JANELA} | Limiar: ${LIMIAR} | TTL: ${TTL} | Dry-run: ${DRYRUN}"
        echo ""
        echo "--- Top 10 IPs com mais falhas ---"
        if [[ -n "${ips}" ]]; then
            echo "${ips}" | head -n 10
        else
            echo "(nenhum)"
        fi
        echo ""
        echo "--- Top 10 usuários mais visados ---"
        if [[ -n "${usuarios}" ]]; then
            echo "${usuarios}" | head -n 10
        else
            echo "(nenhum)"
        fi
        echo "=================================================="
    } | tee -a "${LOG}"
}

ip_esta_na_lista_de_excecoes() {
    local ip="$1"
    local excecoes="$2"
    if [[ -z "${excecoes}" ]]; then
        return 1
    fi
    grep -qxF "${ip}" <<< "${excecoes}"
}

processar_ips() {
    local falhas="$1"
    local excecoes="$2"
    local achados=0
    local contagem ip

    while read -r contagem ip; do
        if [[ -z "${ip:-}" ]]; then
            continue
        fi

        if ip_esta_na_lista_de_excecoes "${ip}" "${excecoes}"; then
            log "INFO" "IP ${ip} está na lista de exceções (${contagem} falhas). Ignorado."
            continue
        fi

        if [[ "${contagem}" -ge "${LIMIAR}" ]]; then
            log "WARN" "IP ${ip} excedeu o limiar (${contagem} >= ${LIMIAR})."
            bloquear_ip "${ip}"
            achados=1
        fi
    done <<< "${falhas}"

    return "${achados}"
}

main() {
    parse_argumentos "$@"
    verificar_privilegio
    verificar_dependencias

    TMP="$(mktemp -d)"

    log "INFO" "Iniciando ${NOME} (limiar=${LIMIAR}, ttl=${TTL}, janela='${JANELA}', dry-run=${DRYRUN})"

    local excecoes falhas_ip usuarios_visados achados
    achados=0

    excecoes="$(carregar_excecoes)"
    falhas_ip="$(extrair_falhas_por_ip)"
    usuarios_visados="$(extrair_usuarios_visados)"

    if [[ -n "${falhas_ip}" ]]; then
        if ! processar_ips "${falhas_ip}" "${excecoes}"; then
            achados=1
        fi
    else
        log "INFO" "Nenhuma falha de autenticação encontrada na janela analisada."
    fi

    gerar_relatorio "${falhas_ip}" "${usuarios_visados}"
    log "INFO" "Execução finalizada."

    if [[ "${achados}" -eq 1 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
