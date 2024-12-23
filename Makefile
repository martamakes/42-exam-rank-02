# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: mvigara- <mvigara-@student.42school.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/11/11 18:44:00 by mvigara-          #+#    #+#              #
#    Updated: 2024/11/11 20:26:05 by mvigara-         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Colores para la salida
GREEN = \033[0;32m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m

# Directorios
EXAM_DIR = 02
RENDU_DIR = rendu

# Regla principal
all: check_dir run_exam

# Verificar que existe el directorio y los archivos necesarios
check_dir:
	@if [ ! -d "$(EXAM_DIR)" ]; then \
		echo "$(RED)Error: No se encuentra el directorio $(EXAM_DIR)$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(EXAM_DIR)/exam.sh" ]; then \
		echo "$(RED)Error: No se encuentra exam.sh$(NC)"; \
		exit 1; \
	fi
	@mkdir -p $(RENDU_DIR)
	@mkdir -p $(EXAM_DIR)/exam_progress
	@chmod +x $(EXAM_DIR)/exam.sh
	@chmod +x $(EXAM_DIR)/init.sh

# Ejecutar el examen
run_exam:
	@echo "$(BLUE)Iniciando sistema de exámenes...$(NC)"
	@cd $(EXAM_DIR) && ./exam.sh

# Limpiar archivos temporales y progreso
clean:
	@echo "$(BLUE)Limpiando archivos temporales...$(NC)"
	@rm -rf $(EXAM_DIR)/exam_progress/*
	@find . -name "*.o" -type f -delete
	@find . -name "a.out" -type f -delete

# Limpiar todo y resetear el progreso
fclean: clean
	@echo "$(BLUE)Reseteando todo el progreso...$(NC)"
	@rm -rf $(EXAM_DIR)/exam_progress/*
	@rm -rf $(RENDU_DIR)/*

# Reinstalar/Resetear todo
re: fclean all

.PHONY: all clean fclean re check_dir run_exam