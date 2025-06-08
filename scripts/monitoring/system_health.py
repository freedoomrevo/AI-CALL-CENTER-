#!/usr/bin/env python3
"""
Aetherium System Health Monitoring Script
Comprehensive health checks for all system components
"""

import asyncio
import json
import logging
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import aiohttp
import asyncpg
import redis.asyncio as redis
import psutil

# Add backend to path
sys.path.append(str(Path(__file__).parent.parent / "backend"))

class HealthChecker:
    def __init__(self):
        self.results = {}
        self.start_time = time.time()
        
        # Configuration from environment
        self.database_url = os.getenv("DATABASE_URL", "postgresql://demo_user:demo_password_123@localhost:5432/aetherium_demo")
        self.redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        self.backend_url = os.getenv("BACKEND_URL", "http://localhost:8000")
        self.frontend_url = os.getenv("FRONTEND_URL", "http://localhost:12001")
        
        # Thresholds
        self.cpu_threshold = float(os.getenv("CPU_THRESHOLD", "80.0"))
        self.memory_threshold = float(os.getenv("MEMORY_THRESHOLD", "85.0"))
        self.disk_threshold = float(os.getenv("DISK_THRESHOLD", "90.0"))
        self.response_time_threshold = float(os.getenv("RESPONSE_TIME_THRESHOLD", "5.0"))
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    async def check_database(self) -> Dict:
        """Check PostgreSQL database connectivity and performance"""
        check_name = "database"
        start_time = time.time()
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Basic connectivity test
            await conn.execute("SELECT 1")
            
            # Check database size
            size_result = await conn.fetchrow("""
                SELECT pg_size_pretty(pg_database_size(current_database())) as size
            """)
            
            # Check active connections
            connections_result = await conn.fetchrow("""
                SELECT count(*) as active_connections 
                FROM pg_stat_activity 
                WHERE state = 'active'
            """)
            
            # Check table counts
            tables_result = await conn.fetchrow("""
                SELECT count(*) as table_count 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """)
            
            await conn.close()
            
            response_time = time.time() - start_time
            
            return {
                "status": "healthy",
                "response_time": round(response_time, 3),
                "details": {
                    "database_size": size_result["size"],
                    "active_connections": connections_result["active_connections"],
                    "table_count": tables_result["table_count"]
                }
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "response_time": time.time() - start_time
            }

    async def check_redis(self) -> Dict:
        """Check Redis connectivity and performance"""
        start_time = time.time()
        
        try:
            r = redis.from_url(self.redis_url)
            
            # Basic connectivity test
            await r.ping()
            
            # Get Redis info
            info = await r.info()
            
            # Test set/get operation
            test_key = "health_check_test"
            await r.set(test_key, "test_value", ex=60)
            test_value = await r.get(test_key)
            await r.delete(test_key)
            
            await r.close()
            
            response_time = time.time() - start_time
            
            return {
                "status": "healthy",
                "response_time": round(response_time, 3),
                "details": {
                    "redis_version": info.get("redis_version"),
                    "used_memory": info.get("used_memory_human"),
                    "connected_clients": info.get("connected_clients"),
                    "total_commands_processed": info.get("total_commands_processed")
                }
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "response_time": time.time() - start_time
            }

    async def check_http_service(self, name: str, url: str, endpoint: str = "/health") -> Dict:
        """Check HTTP service health"""
        start_time = time.time()
        full_url = f"{url}{endpoint}"
        
        try:
            timeout = aiohttp.ClientTimeout(total=10)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(full_url) as response:
                    response_time = time.time() - start_time
                    
                    if response.status == 200:
                        try:
                            data = await response.json()
                            return {
                                "status": "healthy",
                                "response_time": round(response_time, 3),
                                "http_status": response.status,
                                "details": data
                            }
                        except:
                            return {
                                "status": "healthy",
                                "response_time": round(response_time, 3),
                                "http_status": response.status,
                                "details": {"content_type": response.content_type}
                            }
                    else:
                        return {
                            "status": "unhealthy",
                            "response_time": round(response_time, 3),
                            "http_status": response.status,
                            "error": f"HTTP {response.status}"
                        }
                        
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "response_time": time.time() - start_time
            }

    def check_system_resources(self) -> Dict:
        """Check system resource usage"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            # Disk usage
            disk = psutil.disk_usage('/')
            disk_percent = disk.percent
            
            # Load average (Unix only)
            try:
                load_avg = os.getloadavg()
            except:
                load_avg = [0, 0, 0]
            
            # Network stats
            network = psutil.net_io_counters()
            
            # Process count
            process_count = len(psutil.pids())
            
            status = "healthy"
            warnings = []
            
            if cpu_percent > self.cpu_threshold:
                status = "warning"
                warnings.append(f"High CPU usage: {cpu_percent}%")
                
            if memory_percent > self.memory_threshold:
                status = "warning"
                warnings.append(f"High memory usage: {memory_percent}%")
                
            if disk_percent > self.disk_threshold:
                status = "critical"
                warnings.append(f"High disk usage: {disk_percent}%")
            
            return {
                "status": status,
                "warnings": warnings,
                "details": {
                    "cpu_percent": round(cpu_percent, 2),
                    "memory_percent": round(memory_percent, 2),
                    "memory_available_gb": round(memory.available / (1024**3), 2),
                    "disk_percent": round(disk_percent, 2),
                    "disk_free_gb": round(disk.free / (1024**3), 2),
                    "load_average": [round(x, 2) for x in load_avg],
                    "process_count": process_count,
                    "network_bytes_sent": network.bytes_sent,
                    "network_bytes_recv": network.bytes_recv
                }
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e)
            }

    def check_docker_containers(self) -> Dict:
        """Check Docker container status"""
        try:
            import docker
            client = docker.from_env()
            
            containers = client.containers.list(all=True)
            container_status = {}
            
            for container in containers:
                if "aetherium" in container.name.lower():
                    container_status[container.name] = {
                        "status": container.status,
                        "image": container.image.tags[0] if container.image.tags else "unknown",
                        "created": container.attrs["Created"],
                        "ports": container.ports
                    }
            
            healthy_count = sum(1 for c in container_status.values() if c["status"] == "running")
            total_count = len(container_status)
            
            status = "healthy" if healthy_count == total_count else "warning"
            
            return {
                "status": status,
                "details": {
                    "total_containers": total_count,
                    "running_containers": healthy_count,
                    "containers": container_status
                }
            }
            
        except Exception as e:
            return {
                "status": "unknown",
                "error": str(e),
                "details": {"message": "Docker not available or accessible"}
            }

    async def run_all_checks(self) -> Dict:
        """Run all health checks"""
        self.logger.info("Starting comprehensive health check...")
        
        checks = {
            "database": self.check_database(),
            "redis": self.check_redis(),
            "backend": self.check_http_service("backend", self.backend_url),
            "frontend": self.check_http_service("frontend", self.frontend_url, "/"),
            "system_resources": self.check_system_resources(),
            "docker_containers": self.check_docker_containers()
        }
        
        # Run async checks
        async_results = await asyncio.gather(
            checks["database"],
            checks["redis"],
            checks["backend"],
            checks["frontend"],
            return_exceptions=True
        )
        
        # Combine results
        results = {
            "timestamp": datetime.utcnow().isoformat(),
            "total_check_time": round(time.time() - self.start_time, 3),
            "checks": {
                "database": async_results[0] if not isinstance(async_results[0], Exception) else {"status": "error", "error": str(async_results[0])},
                "redis": async_results[1] if not isinstance(async_results[1], Exception) else {"status": "error", "error": str(async_results[1])},
                "backend": async_results[2] if not isinstance(async_results[2], Exception) else {"status": "error", "error": str(async_results[2])},
                "frontend": async_results[3] if not isinstance(async_results[3], Exception) else {"status": "error", "error": str(async_results[3])},
                "system_resources": checks["system_resources"],
                "docker_containers": checks["docker_containers"]
            }
        }
        
        # Calculate overall health
        healthy_checks = sum(1 for check in results["checks"].values() if check.get("status") == "healthy")
        total_checks = len(results["checks"])
        health_percentage = (healthy_checks / total_checks) * 100
        
        if health_percentage >= 90:
            overall_status = "healthy"
        elif health_percentage >= 70:
            overall_status = "warning"
        else:
            overall_status = "critical"
        
        results["overall"] = {
            "status": overall_status,
            "health_percentage": round(health_percentage, 1),
            "healthy_checks": healthy_checks,
            "total_checks": total_checks
        }
        
        return results

    def print_results(self, results: Dict):
        """Print formatted health check results"""
        print("\n" + "="*60)
        print("🏥 AETHERIUM SYSTEM HEALTH CHECK")
        print("="*60)
        
        overall = results["overall"]
        status_emoji = {"healthy": "✅", "warning": "⚠️", "critical": "❌", "unknown": "❓"}
        
        print(f"\n📊 Overall Status: {status_emoji.get(overall['status'], '❓')} {overall['status'].upper()}")
        print(f"📈 Health Score: {overall['health_percentage']}% ({overall['healthy_checks']}/{overall['total_checks']} checks passed)")
        print(f"⏱️  Total Check Time: {results['total_check_time']}s")
        print(f"🕐 Timestamp: {results['timestamp']}")
        
        print("\n📋 Individual Check Results:")
        print("-" * 40)
        
        for check_name, check_result in results["checks"].items():
            status = check_result.get("status", "unknown")
            emoji = status_emoji.get(status, "❓")
            
            print(f"\n{emoji} {check_name.upper()}")
            print(f"   Status: {status}")
            
            if "response_time" in check_result:
                print(f"   Response Time: {check_result['response_time']}s")
                
            if "error" in check_result:
                print(f"   Error: {check_result['error']}")
                
            if "warnings" in check_result and check_result["warnings"]:
                print(f"   Warnings: {', '.join(check_result['warnings'])}")
                
            if "details" in check_result:
                details = check_result["details"]
                if isinstance(details, dict):
                    for key, value in details.items():
                        if key not in ["containers"]:  # Skip verbose details
                            print(f"   {key}: {value}")

async def main():
    """Main function"""
    checker = HealthChecker()
    results = await checker.run_all_checks()
    
    # Print results to console
    checker.print_results(results)
    
    # Save results to file
    output_file = os.getenv("HEALTH_CHECK_OUTPUT", "/tmp/health_check_results.json")
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_file}")
    
    # Exit with appropriate code
    overall_status = results["overall"]["status"]
    if overall_status == "healthy":
        sys.exit(0)
    elif overall_status == "warning":
        sys.exit(1)
    else:
        sys.exit(2)

if __name__ == "__main__":
    asyncio.run(main())