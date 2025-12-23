#!/bin/bash
# Docker runner script with interactive menu
set -e

# =======================
# Colors
# =======================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =======================
# Configuration
# =======================
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$DIR")")"
COMPOSE_FILE="infra/docker/docker-compose.yml"
ENV_FILE="env/docker.env"
DEFAULT_SHELL="bash"

# =======================
# Header
# =======================
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   SellIt Docker Environment Manager   ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "Project Root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# =======================
# Menu
# =======================
show_menu() {
    echo -e "\n${YELLOW}Select an option:${NC}"
    echo -e "1)  ${GREEN}🚀 Build & Up${NC}          (Full start with rebuild)"
    echo -e "2)  ${GREEN}▶️  Up (No Build)${NC}        (Quick start)"
    echo -e "3)  ${RED}🛑 Down${NC}                (Stop containers)"
    echo -e "4)  ${BLUE}🔄 Restart${NC}             (Down then Up)"
    echo -e "5)  ${BLUE}📋 View Logs${NC}           (Follow logs)"
    echo -e "6)  ${BLUE}📦 List Containers${NC}     (docker ps)"
    echo -e "7)  ${BLUE}💻 Shell Access${NC}        (Exec into container)"
    echo -e "8)  ${BLUE}🔍 Inspect Container${NC}   (Env, ports, volumes)"
    echo -e "9)  ${RED}🧹 Clean Wipe${NC}           (Down + Volumes)"
    echo -e "10) ${RED}💥 Full Destruction${NC}    (Down + Volumes + Images)"
    echo -e "11) Exit"
}

# =======================
# Helpers
# =======================
pause() {
    echo -e "\nPress Enter to continue..."
    read
}

container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

# =======================
# Main Loop
# =======================
while true; do
    show_menu
    read -p "Enter choice [1-11]: " choice

    case $choice in
        1)
            echo -e "${GREEN}Building and starting containers...${NC}"
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up --build -d
            echo -e "${GREEN}Done.${NC}"
            ;;
        2)
            echo -e "${GREEN}Starting containers...${NC}"
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
            echo -e "${GREEN}Done.${NC}"
            ;;
        3)
            echo -e "${RED}Stopping containers...${NC}"
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
            echo -e "${RED}Stopped.${NC}"
            ;;
        4)
            echo -e "${BLUE}Restarting containers...${NC}"
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
            echo -e "${GREEN}Restarted.${NC}"
            ;;
        5)
            echo -e "${BLUE}Following logs (Ctrl+C to exit)...${NC}"
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
            ;;
        6)
            echo -e "${BLUE}Running containers:${NC}"
            docker ps
            echo
            read -p "Show all containers (including stopped)? (y/N): " all
            if [[ $all =~ ^[yY]$ ]]; then
                docker ps -a
            fi
            ;;
        7)
            read -p "Enter container name: " cname
            if container_exists "$cname"; then
                docker exec -it "$cname" $DEFAULT_SHELL || docker exec -it "$cname" sh
            else
                echo -e "${RED}Container not found.${NC}"
            fi
            ;;
        8)
            read -p "Enter container name: " cname
            if container_exists "$cname"; then
                docker inspect "$cname"
            else
                echo -e "${RED}Container not found.${NC}"
            fi
            ;;
        9)
            echo -e "${RED}WARNING: This will delete volumes (DB reset).${NC}"
            read -p "Are you sure? (y/N): " confirm
            if [[ $confirm =~ ^[yY]$ ]]; then
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v
                echo -e "${RED}Volumes removed.${NC}"
            else
                echo "Cancelled."
            fi
            ;;
        10)
            echo -e "${RED}WARNING: This will delete containers, volumes, AND images.${NC}"
            read -p "Are you absolutely sure? (y/N): " confirm
            if [[ $confirm =~ ^[yY]$ ]]; then
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v --rmi all
                echo -e "${RED}Everything destroyed.${NC}"
            else
                echo "Cancelled."
            fi
            ;;
        11)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac

    pause
done
