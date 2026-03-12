#!/bin/bash
# =============================================================================
# setup.sh — Setup iniziale SuiteCRM Docker
#
# Uso:
#   chmod +x setup.sh
#   ./setup.sh
# =============================================================================

set -e

# ---------------------------------------------------------------------------
# Carica variabili da .env se esiste
# ---------------------------------------------------------------------------
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "ERRORE: file .env non trovato."
    echo "Copia il template: cp .env.example .env"
    echo "Poi personalizza le variabili e riesegui."
    exit 1
fi

DATA_DIR="${DATA_DIR:-/opt/suitecrm/data}"

echo ""
echo "========================================"
echo "  SuiteCRM Docker — Setup iniziale"
echo "========================================"
echo ""

# ---------------------------------------------------------------------------
# 1. Crea struttura cartelle
# ---------------------------------------------------------------------------
echo "[1/3] Creazione cartelle in $DATA_DIR ..."
mkdir -p "$DATA_DIR/"{db,upload,custom,modules,cache,logs}

# File config vuoti — l'installer scrive direttamente sul bind mount
# evitando il docker cp manuale dopo il wizard
touch "$DATA_DIR/config.php"
touch "$DATA_DIR/config_override.php"

echo "      OK"

# ---------------------------------------------------------------------------
# 2. Verifica Docker
# ---------------------------------------------------------------------------
echo "[2/3] Verifica Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "      ERRORE: Docker non è in esecuzione."
    exit 1
fi
echo "      OK"

# ---------------------------------------------------------------------------
# 3. Verifica docker compose
# ---------------------------------------------------------------------------
echo "[3/3] Verifica Docker Compose..."
if ! docker compose version > /dev/null 2>&1; then
    echo "      ERRORE: Docker Compose plugin non trovato."
    exit 1
fi
echo "      OK"

# ---------------------------------------------------------------------------
# Riepilogo
# ---------------------------------------------------------------------------
HOST_IP=$(hostname -I | awk '{print $1}')
PORT="${HTTP_PORT:-8080}"

echo ""
echo "========================================"
echo "  Setup completato!"
echo "========================================"
echo ""
echo "Prossimi passi:"
echo ""
echo "  1. Avvia lo stack:"
echo "     docker compose up -d"
echo ""
echo "  2. Attendi ~30 secondi poi apri il browser:"
echo "     http://${HOST_IP}:${PORT}"
echo ""
echo "  3. Completa il wizard con questi dati DB:"
echo "     Host:     db"
echo "     Port:     3306"
echo "     Database: ${DB_NAME}"
echo "     User:     ${DB_USER}"
echo "     Password: ${DB_PASSWORD}"
echo ""
echo "  NOTA: config.php è già configurato come bind mount."
echo "  I dati sopravvivono ai riavvii senza docker cp."
echo ""
