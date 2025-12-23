#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Local Setup...${NC}"

# 1. Update Apt
echo -e "${GREEN}Updating apt...${NC}"
sudo apt update

# 2. Check/Install Python venv
echo -e "${GREEN}Checking Python venv support...${NC}"
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    echo "Installing python3-venv..."
    sudo apt install -y python3-venv
fi

# 3. Create venv
if [ ! -d "venv" ]; then
    echo -e "${GREEN}Creating virtual environment...${NC}"
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

# 4. Install requirements
echo -e "${GREEN}Installing requirements...${NC}"
./venv/bin/pip install -r requirements.txt

# Load env vars
set -a
[ -f "../../env/common.env" ] && source ../../env/common.env
[ -f "../../env/local.env" ] && source ../../env/local.env
set +a

# 5. Postgres check/install
echo -e "${GREEN}Checking PostgreSQL ${PG_VERSION}...${NC}"

if ! command -v psql >/dev/null 2>&1; then
    echo "Postgres not found. Installing PostgreSQL ${PG_VERSION}..."
    
    # Add PGDG repo for specific version if needed
    sudo apt install -y curl ca-certificates gnupg
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt update
    sudo apt install -y postgresql-${PG_VERSION} postgresql-contrib-${PG_VERSION}
else
    CURRENT_PG=$(psql --version | awk '{print $3}' | cut -d. -f1)
    if [ "$CURRENT_PG" != "$PG_VERSION" ]; then
        echo -e "${RED}Warning: Found PostgreSQL $CURRENT_PG, but setup expects $PG_VERSION.${NC}"
        # We don't force uninstall, just warn.
    else
        echo "PostgreSQL ${PG_VERSION} is installed."
    fi
fi

# 6. Start Service
echo -e "${GREEN}Starting PostgreSQL service...${NC}"
sudo service postgresql start

# 7. Create DB


# Default values if not in env
DB_USER=${DB_USER:-sellit_user}
DB_PASSWORD=${DB_PASSWORD:-secret_password}
DB_NAME=${DB_NAME:-sellit_db}

echo -e "${GREEN}Ensuring Database Exists...${NC}"
# Check if DB exists
# Note: This requires sudo access to postgres user
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    echo "User $DB_USER already exists."
else
    echo "Creating user $DB_USER..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "Database $DB_NAME already exists."
else
    echo "Creating database $DB_NAME..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

echo -e "${GREEN}Setup Complete!${NC}"
