#!/bin/bash

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para determinar si el ejercicio es un programa o una función
is_program() {
    local readme="$1"
    # Si contiene "Write a program" es un programa, si contiene "Write a function" es una función
    if grep -q "Write a program" "$readme"; then
        return 0 # Es un programa
    else
        return 1 # Es una función
    fi
}

# Función para detectar si necesita archivo .h
needs_header() {
    local readme="$1"
    # Si menciona un .h o describe una estructura
    if grep -q "\.h\|struct\|typedef" "$readme"; then
        return 0 # Necesita header
    else
        return 1 # No necesita header
    fi
}

# Función para crear el test_main.c para programas
create_program_main() {
    local exercise=$1
    cat > "test_main.c" << EOF
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Función para ejecutar el programa y comparar la salida
void test_program(char **args, char *expected) {
    // Crear pipe para capturar la salida
    int pipefd[2];
    pipe(pipefd);
    
    int pid = fork();
    if (pid == 0) {
        // Proceso hijo
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        execv("./${exercise}", args);
        exit(1);
    } else {
        // Proceso padre
        close(pipefd[1]);
        char buffer[1024] = {0};
        read(pipefd[0], buffer, sizeof(buffer));
        
        if (strcmp(buffer, expected) == 0)
            printf("Test passed ✓\\n");
        else {
            printf("Test failed ✗\\n");
            printf("Expected: %s\\n", expected);
            printf("Got     : %s\\n", buffer);
        }
    }
}

int main(void) {
    char *args1[] = {"./${exercise}", "arg1", "arg2", NULL};
    test_program(args1, "expected_output\\n");
    return 0;
}
EOF
}

# Función para crear el test_main.c para funciones
create_function_main() {
    local exercise=$1
    local needs_header=$2
    
    # Header include si es necesario
    local header_include=""
    if [ "$needs_header" = true ]; then
        header_include="#include \"${exercise}.h\""
    fi
    
    cat > "test_main.c" << EOF
#include <stdio.h>
${header_include}

// Prototipos de las funciones a testear (si no hay header)
#ifndef ${exercise}_h
// Aquí irían los prototipos necesarios
#endif

void test_function(char *test_name, int expected, int got) {
    if (expected == got)
        printf("%s: OK ✓\\n", test_name);
    else {
        printf("%s: KO ✗\\n", test_name);
        printf("Expected: %d\\n", expected);
        printf("Got     : %d\\n", got);
    }
}

int main(void) {
    // Aquí irían los casos de test específicos para la función
    return 0;
}
EOF
}

# Función para crear el test.sh
create_test_script() {
    local exercise=$1
    local is_prog=$2
    
    cat > "test.sh" << EOF
#!/bin/bash

# Colores
GREEN='\\033[0;32m'
RED='\\033[0;31m'
NC='\\033[0m'

# Directorios
TESTDIR=\$(dirname \$0)
EXERCISE=${exercise}
STUDENT_DIR="../../../rendu/\$EXERCISE"

# Verificar que existe el directorio del estudiante
if [ ! -d "\$STUDENT_DIR" ]; then
    echo -e "\${RED}Error: No se encuentra el directorio \$STUDENT_DIR\${NC}"
    exit 1
fi

# Copiar archivos necesarios
cp \$STUDENT_DIR/* .
EOF

    if [ "$is_prog" = true ]; then
        # Añadir compilación para programa
        cat >> "test.sh" << EOF

# Compilar programa
gcc -Wall -Wextra -Werror *.c -o \$EXERCISE
if [ \$? -ne 0 ]; then
    echo -e "\${RED}Error de compilación\${NC}"
    exit 1
fi

# Ejecutar tests
./test_main
result=\$?

# Limpiar
rm -f \$EXERCISE *.o

exit \$result
EOF
    else
        # Añadir compilación para función
        cat >> "test.sh" << EOF

# Compilar tests
gcc -Wall -Wextra -Werror test_main.c *.c -o test_prog
if [ \$? -ne 0 ]; then
    echo -e "\${RED}Error de compilación\${NC}"
    exit 1
fi

# Ejecutar tests
./test_prog
result=\$?

# Limpiar
rm -f test_prog *.o

exit \$result
EOF
    fi
    
    chmod +x "test.sh"
}

# Función principal para inicializar la estructura de testing
init_grademe() {
    local level_dir=$1
    local exercise_dir=$2
    
    echo -e "${BLUE}Verificando tests para $exercise_dir...${NC}"
    
    # Verificar que existe el directorio grademe y sus archivos
    local grademe_dir="$level_dir/$exercise_dir/grademe"
    
    # Verificar y crear directorio grademe si no existe
    if [ ! -d "$grademe_dir" ]; then
        echo -e "${RED}Error: No se encuentra el directorio de tests para $exercise_dir${NC}"
        echo -e "${YELLOW}Creando directorio: $grademe_dir${NC}"
        if ! mkdir -p "$grademe_dir"; then
            echo -e "${RED}Error: No se pudo crear el directorio de tests${NC}"
            return 1
        fi
    fi
    
    # Verificar y crear test.sh si no existe
    if [ ! -f "$grademe_dir/test.sh" ]; then
        echo -e "${RED}Error: Falta test.sh en $exercise_dir${NC}"
        echo -e "${YELLOW}Creando archivo: $grademe_dir/test.sh${NC}"
        create_test_script "$grademe_dir" "$exercise_dir"
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    # Verificar y crear test_main.c si no existe 
    if [ ! -f "$grademe_dir/test_main.c" ]; then
        echo -e "${RED}Error: Falta test_main.c en $exercise_dir${NC}"
        echo -e "${YELLOW}Creando archivo: $grademe_dir/test_main.c${NC}"
        create_test_main "$grademe_dir" "$exercise_dir"
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    # Asegurar permisos de ejecución
    chmod +x "$grademe_dir/test.sh"
    
    echo -e "${GREEN}Tests verificados correctamente${NC}"
    return 0
}

# Uso del script
if [ $# -ne 2 ]; then
    echo "Uso: $0 <nivel> <ejercicio>"
    echo "Ejemplo: $0 Level1 first_word"
    exit 1
fi

LEVEL=$1
EXERCISE=$2

# Verificar que existe el directorio
if [ ! -d "$LEVEL/$EXERCISE" ]; then
    echo -e "${RED}Error: No se encuentra el directorio $LEVEL/$EXERCISE${NC}"
    exit 1
fi

init_grademe "$LEVEL" "$EXERCISE"