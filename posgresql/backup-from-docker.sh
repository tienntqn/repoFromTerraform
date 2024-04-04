#!/bin/bash

# Set the current date as the backup timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# PostgreSQL container name
CONTAINER_NAME="postgres"

# PostgreSQL database name
DATABASE_NAME="your_database_name"

# AWS S3 bucket name
S3_BUCKET="your_s3_bucket_name"

# AWS S3 bucket directory
S3_DIRECTORY="backups"

# Filename for the backup file
BACKUP_FILE="${DATABASE_NAME}_${TIMESTAMP}.sql"

# Filename for the tar archive
TAR_FILE="${BACKUP_FILE}.tar.gz"

# Perform the database backup
docker exec -t $CONTAINER_NAME pg_dump -U postgres $DATABASE_NAME > $BACKUP_FILE

# Check if backup file was created successfully and is not empty
if [ -s "$BACKUP_FILE" ]; then
  echo "Database backup successful: $BACKUP_FILE"

  # Create a tar archive
  tar -czvf $TAR_FILE $BACKUP_FILE

  # Check if tar was successful
  if [ $? -eq 0 ]; then
    echo "Backup file compressed successfully: $TAR_FILE"

    # Upload the tar archive to S3
    aws s3 cp $TAR_FILE s3://$S3_BUCKET/$S3_DIRECTORY/

    # Check if upload was successful
    if [ $? -eq 0 ]; then
      echo "Backup file uploaded to S3 successfully: $TAR_FILE"

      # Clean up local backup files
      rm $BACKUP_FILE $TAR_FILE
    else
      echo "Failed to upload backup file to S3"
    fi
  else
    echo "Failed to compress backup file"
  fi
else
  echo "Database backup failed or file is empty"
fi
