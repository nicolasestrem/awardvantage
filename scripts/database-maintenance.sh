#!/usr/bin/env bash
#
# Database Maintenance Script
# Best-Teacher Award #class25
#
# This script performs routine database maintenance including:
# - Health checks
# - Optimization
# - Cleanup of old data
# - Statistics reporting
#
# Usage:
#   bash scripts/database-maintenance.sh [check|optimize|cleanup|full]
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
CONTAINER_NAME="awardvantage-wordpress-1"
DB_CONTAINER="awardvantage-db-1"
BACKUP_DIR="$PROJECT_ROOT/backups/db"

# Load database credentials from .env file
if [ -f "$PROJECT_ROOT/private/.env" ]; then
    # Extract DB credentials from .env file
    DB_USER=$(grep -E '^WORDPRESS_DB_USER=' "$PROJECT_ROOT/private/.env" | cut -d '=' -f 2)
    DB_PASS=$(grep -E '^WORDPRESS_DB_PASSWORD=' "$PROJECT_ROOT/private/.env" | cut -d '=' -f 2)
    DB_NAME=$(grep -E '^WORDPRESS_DB_NAME=' "$PROJECT_ROOT/private/.env" | cut -d '=' -f 2)
else
    print_error ".env file not found at $PROJECT_ROOT/private/.env"
    exit 1
fi

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Check if running in correct directory
check_environment() {
    if [ ! -f "$PROJECT_ROOT/private/.env" ]; then
        print_error "Cannot find .env file. Please run from project root."
        exit 1
    fi

    # Check if containers are running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_error "WordPress container is not running. Please start Docker containers first."
        exit 1
    fi

    print_success "Environment check passed"
}

# Database health check
database_health_check() {
    print_header "DATABASE HEALTH CHECK"

    echo -e "\n${BLUE}Checking database connection...${NC}"
    if docker exec $CONTAINER_NAME wp db check --allow-root 2>/dev/null; then
        print_success "Database connection: OK"
    else
        print_warning "Database check command not available (MySQL client missing)"
        print_info "Checking via WordPress..."
        if docker exec $CONTAINER_NAME wp option get siteurl --allow-root >/dev/null 2>&1; then
            print_success "Database connection: OK (verified via WordPress)"
        else
            print_error "Database connection: FAILED"
            exit 1
        fi
    fi

    echo -e "\n${BLUE}Database Statistics:${NC}"
    docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT
            COUNT(*) as total_tables,
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS total_size_mb,
            ROUND(SUM(data_length) / 1024 / 1024, 2) AS data_size_mb,
            ROUND(SUM(index_length) / 1024 / 1024, 2) AS index_size_mb
        FROM information_schema.TABLES
        WHERE table_schema = '$DB_NAME';
    "

    echo -e "\n${BLUE}Largest Tables:${NC}"
    docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT
            table_name,
            table_rows,
            ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
        FROM information_schema.TABLES
        WHERE table_schema = 'awardvantage'
        ORDER BY (data_length + index_length) DESC
        LIMIT 10;
    "

    echo -e "\n${BLUE}Custom Plugin Tables:${NC}"
    docker exec $CONTAINER_NAME wp db query "
        SELECT
            table_name,
            table_rows
        FROM information_schema.TABLES
        WHERE table_schema = DATABASE()
        AND table_name LIKE 'wp_mt_%'
        ORDER BY table_name;
    " --allow-root 2>/dev/null || docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT table_name, table_rows
        FROM information_schema.TABLES
        WHERE table_schema = 'awardvantage'
        AND table_name LIKE 'wp_mt_%'
        ORDER BY table_name;
    "

    print_success "Health check complete"
}

# Optimize database
optimize_database() {
    print_header "DATABASE OPTIMIZATION"

    echo -e "\n${BLUE}Optimizing all tables...${NC}"

    # Get list of tables
    TABLES=$(docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "SHOW TABLES;")

    COUNT=0
    for TABLE in $TABLES; do
        docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "OPTIMIZE TABLE $TABLE;" >/dev/null 2>&1
        COUNT=$((COUNT+1))
        echo -n "."
    done

    echo ""
    print_success "Optimized $COUNT tables"

    # Check for fragmentation
    echo -e "\n${BLUE}Checking for table fragmentation...${NC}"
    docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT
            table_name,
            ROUND(data_length / 1024 / 1024, 2) AS data_mb,
            ROUND(data_free / 1024 / 1024, 2) AS fragmented_mb,
            ROUND((data_free / data_length) * 100, 2) AS fragmentation_pct
        FROM information_schema.TABLES
        WHERE table_schema = 'awardvantage'
        AND data_free > 0
        ORDER BY data_free DESC
        LIMIT 10;
    "

    print_success "Optimization complete"
}

# Cleanup old data
cleanup_database() {
    print_header "DATABASE CLEANUP"

    echo -e "\n${BLUE}Cleaning up post revisions...${NC}"
    REVISIONS=$(docker exec $CONTAINER_NAME wp post list --post_type=revision --format=count --allow-root)
    if [ "$REVISIONS" -gt 0 ]; then
        docker exec $CONTAINER_NAME wp post delete $(docker exec $CONTAINER_NAME wp post list --post_type=revision --format=ids --allow-root) --force --allow-root >/dev/null 2>&1
        print_success "Deleted $REVISIONS post revisions"
    else
        print_info "No post revisions to clean up"
    fi

    echo -e "\n${BLUE}Cleaning up trash...${NC}"
    TRASH=$(docker exec $CONTAINER_NAME wp post list --post_status=trash --format=count --allow-root)
    if [ "$TRASH" -gt 0 ]; then
        docker exec $CONTAINER_NAME wp post delete $(docker exec $CONTAINER_NAME wp post list --post_status=trash --format=ids --allow-root) --force --allow-root >/dev/null 2>&1
        print_success "Deleted $TRASH trashed posts"
    else
        print_info "No trashed posts to clean up"
    fi

    echo -e "\n${BLUE}Cleaning up spam comments...${NC}"
    SPAM=$(docker exec $CONTAINER_NAME wp comment list --status=spam --format=count --allow-root)
    if [ "$SPAM" -gt 0 ]; then
        docker exec $CONTAINER_NAME wp comment delete $(docker exec $CONTAINER_NAME wp comment list --status=spam --format=ids --allow-root) --force --allow-root >/dev/null 2>&1
        print_success "Deleted $SPAM spam comments"
    else
        print_info "No spam comments to clean up"
    fi

    echo -e "\n${BLUE}Cleaning up expired transients...${NC}"
    docker exec $CONTAINER_NAME wp transient delete --expired --allow-root >/dev/null 2>&1
    print_success "Cleaned up expired transients"

    echo -e "\n${BLUE}Cleaning up orphaned post meta...${NC}"
    ORPHANED=$(docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "
        SELECT COUNT(*) FROM wp_postmeta pm
        LEFT JOIN wp_posts p ON pm.post_id = p.ID
        WHERE p.ID IS NULL;
    ")
    if [ "$ORPHANED" -gt 0 ]; then
        docker exec $DB_CONTAINER mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
            DELETE pm FROM wp_postmeta pm
            LEFT JOIN wp_posts p ON pm.post_id = p.ID
            WHERE p.ID IS NULL;
        " >/dev/null 2>&1
        print_success "Deleted $ORPHANED orphaned post meta rows"
    else
        print_info "No orphaned post meta to clean up"
    fi

    print_success "Cleanup complete"
}

# Full maintenance (all operations)
full_maintenance() {
    print_header "FULL DATABASE MAINTENANCE"

    # Create backup first
    echo -e "\n${BLUE}Creating backup before maintenance...${NC}"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/pre-maintenance-$(date +%Y%m%d-%H%M%S).sql"
    docker exec $CONTAINER_NAME wp db export "$BACKUP_FILE" --allow-root 2>/dev/null || \
        docker exec $DB_CONTAINER mariadb-dump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE"
    print_success "Backup created: $BACKUP_FILE"

    # Run all maintenance tasks
    database_health_check
    echo ""
    cleanup_database
    echo ""
    optimize_database

    # Final report
    echo ""
    print_header "MAINTENANCE COMPLETE"
    print_success "All maintenance tasks completed successfully"
    print_info "Backup saved to: $BACKUP_FILE"
}

# Show usage
show_usage() {
    echo "Usage: bash scripts/database-maintenance.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  check       Run database health check only"
    echo "  optimize    Optimize all database tables"
    echo "  cleanup     Clean up old/orphaned data"
    echo "  full        Run all maintenance tasks (default)"
    echo ""
    echo "Examples:"
    echo "  bash scripts/database-maintenance.sh check"
    echo "  bash scripts/database-maintenance.sh full"
}

# Main script
main() {
    # Check environment
    check_environment

    # Get command
    COMMAND="${1:-full}"

    case "$COMMAND" in
        check)
            database_health_check
            ;;
        optimize)
            optimize_database
            ;;
        cleanup)
            cleanup_database
            ;;
        full)
            full_maintenance
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_success "Database maintenance script completed!"
}

# Run main function
main "$@"
