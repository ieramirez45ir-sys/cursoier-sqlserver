#!/bin/bash
set -e

PASS='CursoSQL2026*'
sql() { docker exec sql2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$PASS" -C "$@"; }

# 1. Levantar los contenedores
docker compose up -d

# 2. Esperar a que SQL Server acepte conexiones
echo "Esperando a SQL Server..."
until sql -Q "SELECT 1" > /dev/null 2>&1; do sleep 3; done

# 3. Descargar el backup si no existe
if [ ! -f AdventureWorksLT2022.bak ]; then
  curl -L -o AdventureWorksLT2022.bak https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak
fi

# 4. Copiarlo al contenedor
docker cp AdventureWorksLT2022.bak sql2022:/tmp/AdventureWorksLT2022.bak

# 5. Restaurar solo si la base no existe
sql -Q "IF DB_ID('AdventureWorksLT2022') IS NULL RESTORE DATABASE AdventureWorksLT2022 FROM DISK = '/tmp/AdventureWorksLT2022.bak' WITH MOVE 'AdventureWorksLT2022_Data' TO '/var/opt/mssql/data/AdventureWorksLT2022.mdf', MOVE 'AdventureWorksLT2022_Log' TO '/var/opt/mssql/data/AdventureWorksLT2022_log.ldf';"

echo "Listo: AdventureWorksLT2022 disponible."
