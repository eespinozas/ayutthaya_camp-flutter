#!/bin/bash

# ========================================
# Script de Cambio de Proyecto Firebase
# ========================================
# Automatiza el cambio a un nuevo proyecto Firebase
# Uso: ./scripts/switch_firebase_project.sh <nuevo-project-id>
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ========================================
# FUNCTIONS
# ========================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_header "Verificando Prerequisitos"

    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter no está instalado"
        exit 1
    fi
    print_success "Flutter instalado"

    # Check Firebase CLI
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI no está instalado"
        print_info "Instalar con: npm install -g firebase-tools"
        exit 1
    fi
    print_success "Firebase CLI instalado"

    # Check if logged in
    if ! firebase projects:list &> /dev/null; then
        print_error "No has iniciado sesión en Firebase CLI"
        print_info "Ejecuta: firebase login"
        exit 1
    fi
    print_success "Firebase CLI autenticado"
}

backup_old_config() {
    print_header "Haciendo Backup de Configuración Actual"

    local backup_dir="$PROJECT_ROOT/.firebase_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup Android
    if [ -f "$PROJECT_ROOT/android/app/google-services.json" ]; then
        cp "$PROJECT_ROOT/android/app/google-services.json" "$backup_dir/"
        print_success "Backup de google-services.json"
    fi

    # Backup iOS
    if [ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]; then
        cp "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" "$backup_dir/"
        print_success "Backup de GoogleService-Info.plist"
    fi

    # Backup .firebaserc
    if [ -f "$PROJECT_ROOT/.firebaserc" ]; then
        cp "$PROJECT_ROOT/.firebaserc" "$backup_dir/"
        print_success "Backup de .firebaserc"
    fi

    # Backup .env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env" "$backup_dir/.env.backup"
        print_success "Backup de .env"
    fi

    print_info "Backup guardado en: $backup_dir"
}

update_firebaserc() {
    local new_project_id=$1
    print_header "Actualizando .firebaserc"

    cat > "$PROJECT_ROOT/.firebaserc" <<EOF
{
  "projects": {
    "default": "$new_project_id"
  }
}
EOF

    print_success ".firebaserc actualizado con project: $new_project_id"
}

switch_firebase_project() {
    local new_project_id=$1
    print_header "Cambiando a Proyecto Firebase: $new_project_id"

    cd "$PROJECT_ROOT"

    if firebase use "$new_project_id" 2>/dev/null; then
        print_success "Proyecto cambiado a: $new_project_id"
    else
        print_warning "No se pudo cambiar con 'firebase use', actualizando .firebaserc manualmente"
        update_firebaserc "$new_project_id"
    fi

    # Verify
    local current_project=$(firebase use 2>/dev/null | grep -o "Now using alias.*" | cut -d' ' -f5 || echo "")
    if [ -n "$current_project" ]; then
        print_success "Proyecto activo: $current_project"
    fi
}

deploy_rules_and_indexes() {
    print_header "Desplegando Rules e Indexes"

    cd "$PROJECT_ROOT"

    # Deploy Firestore rules
    if [ -f "firestore.rules" ]; then
        print_info "Desplegando Firestore rules..."
        if firebase deploy --only firestore:rules; then
            print_success "Firestore rules desplegadas"
        else
            print_error "Error al desplegar Firestore rules"
        fi
    fi

    # Deploy Storage rules
    if [ -f "storage.rules" ]; then
        print_info "Desplegando Storage rules..."
        if firebase deploy --only storage; then
            print_success "Storage rules desplegadas"
        else
            print_error "Error al desplegar Storage rules"
        fi
    fi

    # Deploy Firestore indexes
    if [ -f "firestore.indexes.json" ]; then
        print_info "Desplegando Firestore indexes..."
        if firebase deploy --only firestore:indexes; then
            print_success "Firestore indexes desplegados"
        else
            print_error "Error al desplegar Firestore indexes"
        fi
    fi
}

clean_flutter() {
    print_header "Limpiando Proyecto Flutter"

    cd "$PROJECT_ROOT"

    flutter clean
    print_success "Flutter clean completado"

    flutter pub get
    print_success "Flutter pub get completado"
}

show_next_steps() {
    print_header "Siguientes Pasos Manuales"

    echo -e "${YELLOW}Debes completar estos pasos manualmente:${NC}\n"

    echo "1️⃣  Descargar nuevos archivos de configuración:"
    echo "   • Firebase Console → Project Settings → Your apps"
    echo "   • Android: Descargar google-services.json → android/app/"
    echo "   • iOS: Descargar GoogleService-Info.plist → ios/Runner/"
    echo ""

    echo "2️⃣  Desplegar Cloud Functions (si tienes):"
    echo "   cd functions && npm install && cd .."
    echo "   firebase deploy --only functions"
    echo ""

    echo "3️⃣  Configurar SendGrid (si usas):"
    echo "   firebase functions:secrets:set SENDGRID_API_KEY"
    echo ""

    echo "4️⃣  Probar la app:"
    echo "   flutter run"
    echo ""

    echo "5️⃣  Verificar servicios Firebase:"
    echo "   • Authentication → Habilitar Email/Password"
    echo "   • Firestore → Verificar que existe"
    echo "   • Storage → Verificar que existe"
    echo ""

    print_info "Ver guía completa: MIGRACION_NUEVA_CUENTA.md"
}

# ========================================
# MAIN
# ========================================

main() {
    if [ -z "$1" ]; then
        print_error "Debes proporcionar el ID del nuevo proyecto"
        echo ""
        echo "Uso: $0 <nuevo-project-id>"
        echo ""
        echo "Ejemplo:"
        echo "  $0 ayutthaya-camp"
        echo ""
        print_info "Para ver tus proyectos: firebase projects:list"
        exit 1
    fi

    local new_project_id=$1

    clear
    print_header "🔄 Cambio de Proyecto Firebase"
    echo "Proyecto destino: $new_project_id"
    echo ""

    read -p "¿Continuar? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operación cancelada"
        exit 0
    fi

    check_prerequisites
    backup_old_config
    switch_firebase_project "$new_project_id"
    deploy_rules_and_indexes
    clean_flutter
    show_next_steps

    print_header "✅ Proceso Completado"
    print_success "Proyecto cambiado exitosamente a: $new_project_id"
    print_warning "No olvides completar los pasos manuales arriba"
}

main "$@"
