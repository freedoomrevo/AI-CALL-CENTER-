#!/usr/bin/env python3
"""
Aetherium Database Migration Tool
Handles database schema migrations and data seeding
"""

import asyncio
import os
import sys
from pathlib import Path
from typing import List
import asyncpg
from datetime import datetime

# Add backend to path
sys.path.append(str(Path(__file__).parent.parent))

from database.connection import get_database_url

class MigrationManager:
    def __init__(self):
        self.database_url = get_database_url()
        self.migrations_dir = Path(__file__).parent
        
    async def create_migrations_table(self, conn):
        """Create migrations tracking table if it doesn't exist"""
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                id SERIAL PRIMARY KEY,
                version VARCHAR(50) UNIQUE NOT NULL,
                filename VARCHAR(255) NOT NULL,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                checksum VARCHAR(64)
            )
        """)
        
    async def get_applied_migrations(self, conn) -> List[str]:
        """Get list of already applied migrations"""
        rows = await conn.fetch("SELECT version FROM schema_migrations ORDER BY version")
        return [row['version'] for row in rows]
        
    async def get_migration_files(self) -> List[Path]:
        """Get all migration files sorted by version"""
        migration_files = []
        for file_path in self.migrations_dir.glob("*.sql"):
            if file_path.name.startswith(('001_', '002_', '003_')):  # Only numbered migrations
                migration_files.append(file_path)
        return sorted(migration_files)
        
    async def apply_migration(self, conn, migration_file: Path):
        """Apply a single migration file"""
        print(f"Applying migration: {migration_file.name}")
        
        # Read migration content
        content = migration_file.read_text()
        
        # Calculate checksum
        import hashlib
        checksum = hashlib.sha256(content.encode()).hexdigest()
        
        try:
            # Execute migration in a transaction
            async with conn.transaction():
                await conn.execute(content)
                
                # Record migration as applied
                version = migration_file.stem.split('_')[0]  # Extract version number
                await conn.execute("""
                    INSERT INTO schema_migrations (version, filename, checksum)
                    VALUES ($1, $2, $3)
                    ON CONFLICT (version) DO NOTHING
                """, version, migration_file.name, checksum)
                
            print(f"✅ Successfully applied: {migration_file.name}")
            
        except Exception as e:
            print(f"❌ Failed to apply {migration_file.name}: {e}")
            raise
            
    async def run_migrations(self, target_version: str = None):
        """Run all pending migrations"""
        print("🚀 Starting database migrations...")
        
        conn = await asyncpg.connect(self.database_url)
        try:
            # Create migrations table
            await self.create_migrations_table(conn)
            
            # Get applied migrations
            applied_migrations = await self.get_applied_migrations(conn)
            print(f"📋 Applied migrations: {applied_migrations}")
            
            # Get migration files
            migration_files = await self.get_migration_files()
            
            # Apply pending migrations
            pending_count = 0
            for migration_file in migration_files:
                version = migration_file.stem.split('_')[0]
                
                # Skip if already applied
                if version in applied_migrations:
                    print(f"⏭️  Skipping already applied: {migration_file.name}")
                    continue
                    
                # Stop if we've reached target version
                if target_version and version > target_version:
                    break
                    
                await self.apply_migration(conn, migration_file)
                pending_count += 1
                
            if pending_count == 0:
                print("✨ No pending migrations found. Database is up to date!")
            else:
                print(f"✅ Applied {pending_count} migrations successfully!")
                
        finally:
            await conn.close()
            
    async def rollback_migration(self, version: str):
        """Rollback a specific migration (basic implementation)"""
        print(f"⚠️  Rolling back migration {version}...")
        print("Note: This is a basic rollback that only removes the migration record.")
        print("Manual schema changes may be required.")
        
        conn = await asyncpg.connect(self.database_url)
        try:
            await conn.execute("DELETE FROM schema_migrations WHERE version = $1", version)
            print(f"✅ Removed migration record for version {version}")
        finally:
            await conn.close()
            
    async def status(self):
        """Show migration status"""
        print("📊 Migration Status:")
        
        conn = await asyncpg.connect(self.database_url)
        try:
            await self.create_migrations_table(conn)
            
            # Get applied migrations
            applied_migrations = await self.get_applied_migrations(conn)
            
            # Get all migration files
            migration_files = await self.get_migration_files()
            
            print(f"\n📁 Available migrations: {len(migration_files)}")
            print(f"✅ Applied migrations: {len(applied_migrations)}")
            print(f"⏳ Pending migrations: {len(migration_files) - len(applied_migrations)}")
            
            print("\n📋 Migration Details:")
            for migration_file in migration_files:
                version = migration_file.stem.split('_')[0]
                status = "✅ Applied" if version in applied_migrations else "⏳ Pending"
                print(f"  {version}: {migration_file.name} - {status}")
                
        finally:
            await conn.close()

async def main():
    """Main CLI interface"""
    manager = MigrationManager()
    
    if len(sys.argv) < 2:
        print("Usage: python migrate.py <command> [options]")
        print("Commands:")
        print("  migrate [version]  - Run migrations (optionally up to specific version)")
        print("  rollback <version> - Rollback specific migration")
        print("  status            - Show migration status")
        return
        
    command = sys.argv[1]
    
    try:
        if command == "migrate":
            target_version = sys.argv[2] if len(sys.argv) > 2 else None
            await manager.run_migrations(target_version)
            
        elif command == "rollback":
            if len(sys.argv) < 3:
                print("Error: rollback command requires version argument")
                return
            version = sys.argv[2]
            await manager.rollback_migration(version)
            
        elif command == "status":
            await manager.status()
            
        else:
            print(f"Unknown command: {command}")
            
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())