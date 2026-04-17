#!/bin/bash

# Script para ejecutar tests de Flutter con diferentes configuraciones
# Uso: ./scripts/run_tests.sh [all|unit|coverage|watch]

set -e  # Exit on error

echo "🧪 Ayutthaya Camp - Test Runner"
echo "================================"
echo ""

# Colors
GREEN='\033[0.32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para ejecutar todos los tests
run_all_tests() {
    echo -e "${YELLOW}Ejecutando todos los tests...${NC}"
    flutter test
    echo -e "${GREEN}✅ Todos los tests completados${NC}"
}

# Función para ejecutar solo tests unitarios
run_unit_tests() {
    echo -e "${YELLOW}Ejecutando tests unitarios...${NC}"
    flutter test test/features/ test/core/
    echo -e "${GREEN}✅ Tests unitarios completados${NC}"
}

# Función para generar reporte de cobertura
run_coverage() {
    echo -e "${YELLOW}Generando reporte de cobertura...${NC}"

    # Ejecutar tests con cobertura
    flutter test --coverage

    # Verificar si genhtml está disponible
    if command -v genhtml &> /dev/null; then
        echo -e "${YELLOW}Generando reporte HTML...${NC}"
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}✅ Reporte generado en: coverage/html/index.html${NC}"

        # Abrir en navegador (Linux/macOS)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open coverage/html/index.html 2>/dev/null || echo "Abre manualmente: coverage/html/index.html"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        fi
    else
        echo -e "${YELLOW}⚠️  genhtml no está instalado. Solo se generó coverage/lcov.info${NC}"
        echo -e "${YELLOW}Instala lcov para generar reporte HTML:${NC}"
        echo "  sudo apt-get install lcov  # Ubuntu/Debian"
        echo "  brew install lcov          # macOS"
    fi

    # Mostrar resumen de cobertura
    echo ""
    echo -e "${YELLOW}Resumen de cobertura:${NC}"
    if command -v lcov &> /dev/null; then
        lcov --summary coverage/lcov.info
    fi
}

# Función para ejecutar tests en modo watch
run_watch() {
    echo -e "${YELLOW}Ejecutando tests en modo watch...${NC}"
    echo -e "${YELLOW}Presiona 'r' para re-ejecutar, 'q' para salir${NC}"
    flutter test --watch
}

# Función para ejecutar test de un archivo específico
run_specific() {
    local file=$1
    if [ -z "$file" ]; then
        echo -e "${RED}❌ Error: Especifica un archivo${NC}"
        echo "Uso: ./scripts/run_tests.sh specific <ruta_al_archivo>"
        exit 1
    fi

    echo -e "${YELLOW}Ejecutando: $file${NC}"
    flutter test "$file"
    echo -e "${GREEN}✅ Test completado${NC}"
}

# Función para limpiar archivos de cobertura
clean_coverage() {
    echo -e "${YELLOW}Limpiando archivos de cobertura...${NC}"
    rm -rf coverage/
    echo -e "${GREEN}✅ Archivos de cobertura eliminados${NC}"
}

# Función para verificar threshold de cobertura
check_coverage_threshold() {
    local threshold=${1:-60}
    echo -e "${YELLOW}Verificando threshold de cobertura mínima: ${threshold}%${NC}"

    flutter test --coverage

    if command -v lcov &> /dev/null; then
        local coverage=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')

        if (( $(echo "$coverage >= $threshold" | bc -l) )); then
            echo -e "${GREEN}✅ Cobertura OK: ${coverage}% (>= ${threshold}%)${NC}"
            exit 0
        else
            echo -e "${RED}❌ Cobertura insuficiente: ${coverage}% (< ${threshold}%)${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  lcov no está instalado, no se puede verificar threshold${NC}"
    fi
}

# Mostrar ayuda
show_help() {
    echo "Uso: ./scripts/run_tests.sh [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  all         - Ejecutar todos los tests (default)"
    echo "  unit        - Ejecutar solo tests unitarios"
    echo "  coverage    - Generar reporte de cobertura"
    echo "  watch       - Ejecutar tests en modo watch"
    echo "  specific    - Ejecutar un archivo específico"
    echo "  clean       - Limpiar archivos de cobertura"
    echo "  threshold   - Verificar threshold mínimo (default: 60%)"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./scripts/run_tests.sh"
    echo "  ./scripts/run_tests.sh coverage"
    echo "  ./scripts/run_tests.sh specific test/features/bookings/services/booking_service_test.dart"
    echo "  ./scripts/run_tests.sh threshold 70"
}

# Main
case "${1:-all}" in
    all)
        run_all_tests
        ;;
    unit)
        run_unit_tests
        ;;
    coverage)
        run_coverage
        ;;
    watch)
        run_watch
        ;;
    specific)
        run_specific "$2"
        ;;
    clean)
        clean_coverage
        ;;
    threshold)
        check_coverage_threshold "$2"
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
