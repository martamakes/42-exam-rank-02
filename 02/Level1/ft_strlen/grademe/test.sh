#!/bin/bash

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Directorios
EXERCISE="ft_strlen"
STUDENT_DIR="../../../../rendu/$EXERCISE"

echo "=== Compilando tests para $EXERCISE ==="

# Verificar directorio del estudiante
if [ ! -d "$STUDENT_DIR" ]; then
    echo -e "${RED}Error: No se encuentra el directorio $STUDENT_DIR${NC}"
    exit 1
fi

# Copiar archivo del estudiante
cp "$STUDENT_DIR/$EXERCISE.c" .

# Compilar
gcc -Wall -Wextra -Werror test_main.c ft_strlen.c -o test_prog

if [ $? -ne 0 ]; then
    echo -e "${RED}Error de compilación${NC}"
    exit 1
fi

# Ejecutar tests
./test_prog

# Limpiar
rm -f test_prog ft_strlen.c

exit 0