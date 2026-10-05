#!/usr/bin/env bash

set -u
ulimit -c 0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CODE_DIR="${WORKSPACE}/code"
TESTS_DIR="${WORKSPACE}/tests"
SOURCE="${CODE_DIR}/escuadron.c"
PROGRAM="${CODE_DIR}/escuadron"
TEMP_DIR="$(mktemp -d)" || exit 2
VALIDATION_PROGRAM="${TEMP_DIR}/escuadron"
VALIDATION_COMPILES=0
PASSES=0
FAILURES=0

trap 'rm -rf -- "${TEMP_DIR}"' EXIT

pass() {
    printf 'PASS: %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

check() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        pass "${description}"
    else
        fail "${description}"
    fi
}

is_binary_executable() {
    local path="$1"
    local description=""

    [[ -f "${path}" && -x "${path}" ]] || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" == ELF*executable* ]]
}

compiles_cleanly() {
    [[ "${VALIDATION_COMPILES}" == 1 ]] || return 1
    is_binary_executable "${PROGRAM}"
}

has_debug_symbols() {
    local description=""

    is_binary_executable "${PROGRAM}" || return 1
    description="$(file -b -- "${PROGRAM}")"
    [[ "${description}" == *"with debug_info"* ]]
}

all_test_cases_exist() {
    local number=""

    for number in 001 002 003 004 005; do
        [[ -f "${TESTS_DIR}/test${number}.in" ]] || return 1
        [[ -f "${TESTS_DIR}/test${number}.expected" ]] || return 1
    done
}

program_matches() {
    local input="$1"
    local expected="$2"
    local output_file="${TEMP_DIR}/result.out"
    local expected_file="${TEMP_DIR}/result.expected"

    [[ "${VALIDATION_COMPILES}" == 1 ]] || return 1
    printf '%s' "${expected}" > "${expected_file}"
    {
        timeout 3 "${VALIDATION_PROGRAM}" <<< "${input}" \
            > "${output_file}" 2>/dev/null
    } 2>/dev/null || return 1
    cmp -s -- "${expected_file}" "${output_file}"
}

controls_are_correct() {
    program_matches \
        $'3\n10 2 1\n8 1 1\n12 0 1\n' \
        $'Naves registradas: 3\nNaves operativas: 3\nCeldas requeridas: 33\nPromedio de celdas por nave operativa: 11\n' || return 1
    program_matches \
        $'4\n5 0 1\n7 0 0\n9 0 1\n4 0 0\n' \
        $'Naves registradas: 4\nNaves operativas: 2\nCeldas requeridas: 25\nPromedio de celdas por nave operativa: 7\n'
}

cell_counts_are_correct() {
    program_matches \
        $'10\n10 2 1\n8 0 0\n6 1 1\n12 3 1\n5 0 0\n9 4 1\n7 6 0\n11 2 1\n4 0 0\n8 1 1\n' \
        $'Naves registradas: 10\nNaves operativas: 6\nCeldas requeridas: 99\nPromedio de celdas por nave operativa: 11\n' || return 1
    program_matches \
        $'12\n9 0 0\n6 2 1\n8 0 1\n10 5 0\n4 1 1\n7 0 0\n12 3 1\n5 4 1\n11 2 0\n3 0 1\n9 1 1\n6 0 0\n' \
        $'Naves registradas: 12\nNaves operativas: 7\nCeldas requeridas: 108\nPromedio de celdas por nave operativa: 8\n' || return 1
    program_matches \
        $'3\n3 4 0\n10 2 1\n8 5 0\n' \
        $'Naves registradas: 3\nNaves operativas: 1\nCeldas requeridas: 32\nPromedio de celdas por nave operativa: 12\n'
}

reserve_report_is_correct() {
    program_matches \
        $'6\n8 0 0\n6 0 0\n10 0 0\n4 0 0\n12 0 0\n7 0 0\n' \
        $'Naves registradas: 6\nNaves operativas: 0\nCeldas requeridas: 47\nPromedio de celdas por nave operativa: 0\n' || return 1
    program_matches \
        $'1\n0 0 0\n' \
        $'Naves registradas: 1\nNaves operativas: 0\nCeldas requeridas: 0\nPromedio de celdas por nave operativa: 0\n'
}

has_clean_stderr() {
    local number=""
    local input_file=""
    local executable=""
    local error_file="${TEMP_DIR}/clean.err"

    is_binary_executable "${PROGRAM}" || return 1
    is_binary_executable "${VALIDATION_PROGRAM}" || return 1
    all_test_cases_exist || return 1

    for executable in "${PROGRAM}" "${VALIDATION_PROGRAM}"; do
        for number in 001 002 003 004 005; do
            input_file="${TESTS_DIR}/test${number}.in"
            {
                timeout 3 "${executable}" < "${input_file}" \
                    > /dev/null 2> "${error_file}"
            } 2>/dev/null || return 1
            [[ ! -s "${error_file}" ]] || return 1
        done
    done
}

suite_passes() {
    [[ "${VALIDATION_COMPILES}" == 1 ]] || return 1
    is_binary_executable "${PROGRAM}" || return 1
    all_test_cases_exist || return 1
    [[ -x "${SCRIPT_DIR}/tests-run.sh" ]] || return 1
    "${SCRIPT_DIR}/tests-run.sh" "${PROGRAM}" "${TESTS_DIR}" \
        >/dev/null 2>&1 || return 1
    "${SCRIPT_DIR}/tests-run.sh" "${VALIDATION_PROGRAM}" "${TESTS_DIR}" \
        >/dev/null 2>&1
}

if gcc -Wall -Wextra -Werror -std=c11 -g -O0 "${SOURCE}" \
    -o "${VALIDATION_PROGRAM}" >/dev/null 2>&1; then
    VALIDATION_COMPILES=1
fi

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio PR2   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check '[1.2] El programa compila sin warnings y escuadron corresponde a un binario' compiles_cleanly
check '[1.2] escuadron contiene símbolos de depuración' has_debug_symbols
check '[1.3] tests-run.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/tests-run.sh"
check '[1.3] Existen los cinco pares de archivos de prueba' all_test_cases_exist
check '[2.4] Los casos de control mantienen los resultados esperados' controls_are_correct
check '[2.4] Las celdas requeridas incluyen las celdas base y de emergencia de todas las naves' cell_counts_are_correct
check '[3.4] El informe es correcto cuando todas las naves quedan en reserva' reserve_report_is_correct
check '[4.1] El ejecutable termina sin emitir trazas a stderr' has_clean_stderr
check '[4.1] El código fuente y el ejecutable entregan PASS en la suite completa' suite_passes
check '[4.2] check.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
