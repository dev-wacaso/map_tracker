#!/bin/bash

# Database creation script for PostGIS
# Usage: ./create_db_user.sh [username] [password] [database] [host] [port]

set -e

# Default values
USERNAME=${1:-mapuser}
PASSWORD=${2:-tracker}
DATABASE=${3:-map_tracker}
HOST=${4:-localhost}
PORT=${5:-5432}
POSTGRES_USER=${6:-postgres}

echo "Creating PostgreSQL user and database..."
echo "Username: $USERNAME"
echo "Database: $DATABASE"
echo "Host: $HOST:$PORT"

# Connect to PostgreSQL as superuser and create user/database
PGPASSWORD=$POSTGRES_PASSWORD psql -h $HOST -p $PORT -U $POSTGRES_USER -d postgres << EOF
-- Create the user if it doesn't exist
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$USERNAME') THEN
      CREATE ROLE $USERNAME LOGIN PASSWORD '$PASSWORD';
   END IF;
END
\$\$;

-- Create the database if it doesn't exist
SELECT 'CREATE DATABASE $DATABASE OWNER $USERNAME'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DATABASE')\gexec

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO $USERNAME;

-- Connect to the new database and enable PostGIS extensions
\c $DATABASE

-- Enable PostGIS extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;

-- Grant permissions on PostGIS tables
GRANT ALL ON SCHEMA public TO $USERNAME;
GRANT ALL ON ALL TABLES IN SCHEMA public TO $USERNAME;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $USERNAME;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $USERNAME;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $USERNAME;

EOF

echo "Database setup completed successfully!"
echo "Connection details:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Database: $DATABASE"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo ""
echo "Test connection with:"
echo "  psql -h $HOST -p $PORT -U $USERNAME -d $DATABASE"
