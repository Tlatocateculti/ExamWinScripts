#!/bin/bash

# ============== KONFIGURACJA ==============
PASSWORD="twoje_haslo"
ORIGINAL_SOURCE="admin@10.0.11.101"
SOURCE_FILE="/mnt/virtual/Base.egz"
DEST_PATH="/mnt/virtual/"
TEMP_SUFFIX=".copying"  # Plik tymczasowy podczas kopiowania

# Lista wszystkich 20-23 komputerów w sali
HOSTS=(
    "admin@10.0.11.102"
    "admin@10.0.11.103"
    "admin@10.0.11.104"
    # ... reszta
)

MOUNT_CMD='mount /dev/nvme0n1p4 /mnt/virtual && mount /dev/nvme0n1p5 /mnt/usb && mount /dev/nvme0n1p6 /mnt/vboxpart'

# ============== FUNKCJE ==============

# Funkcja montowania dysków
mount_disks() {
    local host=$1
    echo "[$host] Montowanie dysków..."
    
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$host" \
        "echo '$PASSWORD' | sudo -S $MOUNT_CMD" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "[$host] ✓ Dyski zamontowane"
        return 0
    else
        echo "[$host] ✗ Błąd montowania dysków"
        return 1
    fi
}

# Funkcja kopiowania z atomowym przemianowaniem
copy_file_atomic() {
    local source_host=$1
    local dest_host=$2
    local start_time=$(date +%s)
    
    echo "[$dest_host] Kopiowanie z $source_host..."
    
    # Kopiuj do pliku tymczasowego
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        "$source_host:$SOURCE_FILE" "$dest_host:${DEST_PATH}Base.egz${TEMP_SUFFIX}" 2>&1
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        # Zmień nazwę pliku atomowo (tylko jeśli kopiowanie się udało)
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$dest_host" \
            "mv ${DEST_PATH}Base.egz${TEMP_SUFFIX} ${DEST_PATH}Base.egz" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo "[$dest_host] ✓ Plik skopiowany i zweryfikowany (czas: ${duration}s)"
            return 0
        else
            echo "[$dest_host] ✗ Błąd podczas przemianowania pliku"
            return 1
        fi
    else
        echo "[$dest_host] ✗ Błąd kopiowania"
        # Usuń niepełny plik tymczasowy
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$dest_host" \
            "rm -f ${DEST_PATH}Base.egz${TEMP_SUFFIX}" 2>/dev/null
        return 1
    fi
}

# Funkcja sprawdzająca czy plik KOMPLETNY już istnieje
check_file_complete() {
    local host=$1
    
    # Sprawdź czy istnieje plik finalny (nie tymczasowy)
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$host" \
        "test -f ${DEST_PATH}Base.egz && ! test -f ${DEST_PATH}Base.egz${TEMP_SUFFIX}" 2>/dev/null
    
    return $?
}

# Funkcja czyszcząca niepełne pliki z poprzednich prób
cleanup_incomplete() {
    local host=$1
    echo "[$host] Czyszczenie niepełnych plików..."
    
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$host" \
        "rm -f ${DEST_PATH}Base.egz${TEMP_SUFFIX}" 2>/dev/null
}

# ============== GŁÓWNA LOGIKA ==============

echo "============================================"
echo "  Automatyczne kopiowanie Base.egz"
echo "  Źródło: $ORIGINAL_SOURCE"
echo "  Liczba komputerów: ${#HOSTS[@]}"
echo "  Start: $(date)"
echo "============================================"
echo ""

SUCCESSFUL_HOSTS=()
FAILED_HOSTS=()
IN_PROGRESS=()  # Tablica komputerów obecnie kopiujących

# Krok 1: Kopiuj na pierwszy komputer z oryginalnego źródła
echo "=== ETAP 1: Pierwszy komputer ==="
FIRST_HOST="${HOSTS[0]}"

if check_file_complete "$FIRST_HOST"; then
    echo "[$FIRST_HOST] ⚠ Plik już istnieje, pomijam"
    SUCCESSFUL_HOSTS+=("$FIRST_HOST")
else
    cleanup_incomplete "$FIRST_HOST"
    
    if mount_disks "$FIRST_HOST"; then
        if copy_file_atomic "$ORIGINAL_SOURCE" "$FIRST_HOST"; then
            SUCCESSFUL_HOSTS+=("$FIRST_HOST")
            echo "✓ Pierwszy komputer gotowy do dystrybucji"
        else
            echo "!!! BŁĄD KRYTYCZNY: Nie można skopiować na pierwszy komputer"
            exit 1
        fi
    else
        echo "!!! BŁĄD KRYTYCZNY: Nie można zamontować dysków na pierwszym komputerze"
        exit 1
    fi
fi

echo ""
sleep 2

# Krok 2: Kaskadowe kopiowanie na pozostałe komputery
echo "=== ETAP 2: Kopiowanie kaskadowe ==="

for i in "${!HOSTS[@]}"; do
    # Pomijamy pierwszy komputer
    if [ $i -eq 0 ]; then
        continue
    fi
    
    current_host="${HOSTS[$i]}"
    
    echo ""
    echo "--- Komputer $((i+1))/${#HOSTS[@]}: $current_host ---"
    
    # Sprawdź czy plik KOMPLETNY już istnieje
    if check_file_complete "$current_host"; then
        echo "[$current_host] ⚠ Plik już istnieje (kompletny), pomijam"
        SUCCESSFUL_HOSTS+=("$current_host")
        continue
    fi
    
    # Wyczyść niepełne pliki z poprzednich prób
    cleanup_incomplete "$current_host"
    
    # Montuj dyski
    if ! mount_disks "$current_host"; then
        FAILED_HOSTS+=("$current_host")
        continue
    fi
    
    # Wybierz losowe źródło spośród TYLKO gotowych komputerów
    # (nie tych w trakcie kopiowania)
    if [ ${#SUCCESSFUL_HOSTS[@]} -gt 0 ]; then
        source_index=$((RANDOM % ${#SUCCESSFUL_HOSTS[@]}))
        source_host="${SUCCESSFUL_HOSTS[$source_index]}"
        
        # Zaznacz że kopiowanie w toku
        IN_PROGRESS+=("$current_host")
        
        if copy_file_atomic "$source_host" "$current_host"; then
            SUCCESSFUL_HOSTS+=("$current_host")
            echo "✓ Gotowych komputerów: ${#SUCCESSFUL_HOSTS[@]}/${#HOSTS[@]}"
            
            # Usuń z listy "w trakcie"
            IN_PROGRESS=("${IN_PROGRESS[@]/$current_host}")
        else
            FAILED_HOSTS+=("$current_host")
            IN_PROGRESS=("${IN_PROGRESS[@]/$current_host}")
        fi
    else
        echo "[$current_host] ✗ Brak dostępnych źródeł"
        FAILED_HOSTS+=("$current_host")
    fi
done

# ============== PODSUMOWANIE ==============

echo ""
echo "============================================"
echo "  PODSUMOWANIE"
echo "============================================"
echo "Koniec: $(date)"
echo ""
echo "✓ Sukces: ${#SUCCESSFUL_HOSTS[@]} komputerów"
echo "✗ Błędy: ${#FAILED_HOSTS[@]} komputerów"
echo ""

if [ ${#SUCCESSFUL_HOSTS[@]} -gt 0 ]; then
    echo "Komputery z kompletnym plikiem:"
    for host in "${SUCCESSFUL_HOSTS[@]}"; do
        echo "  ✓ $host"
    done
    echo ""
fi

if [ ${#FAILED_HOSTS[@]} -gt 0 ]; then
    echo "Komputery z błędami:"
    for host in "${FAILED_HOSTS[@]}"; do
        echo "  ✗ $host"
    done
    echo ""
    echo "Możesz uruchomić skrypt ponownie"
fi

echo "============================================"

if [ ${#FAILED_HOSTS[@]} -eq 0 ]; then
    exit 0
else
    exit 1
fi
