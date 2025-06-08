"""
Integration tests for Aetherium API endpoints
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User

class TestAuthEndpoints:
    """Test authentication endpoints."""
    
    async def test_user_registration(self, client: AsyncClient):
        """Test user registration endpoint."""
        user_data = {
            "email": "newuser@example.com",
            "password": "password123",
            "confirm_password": "password123",
            "phone_number": "+1234567890"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "user_id" in data
        assert "verification_required" in data
        assert data["verification_required"] is True
        
    async def test_user_registration_duplicate_email(
        self, 
        client: AsyncClient,
        test_user: User
    ):
        """Test registration with duplicate email."""
        user_data = {
            "email": test_user.email,
            "password": "password123",
            "confirm_password": "password123",
            "phone_number": "+1987654321"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        
        assert response.status_code == 400
        data = response.json()
        assert "already exists" in data["detail"].lower()
        
    async def test_user_registration_password_mismatch(self, client: AsyncClient):
        """Test registration with password mismatch."""
        user_data = {
            "email": "test@example.com",
            "password": "password123",
            "confirm_password": "different_password",
            "phone_number": "+1234567890"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        
        assert response.status_code == 400
        data = response.json()
        assert "password" in data["detail"].lower()
        
    async def test_user_login(self, client: AsyncClient, test_user: User):
        """Test user login endpoint."""
        login_data = {
            "login_identifier": test_user.email,
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "token_type" in data
        assert data["token_type"] == "bearer"
        assert data["user_id"] == test_user.id
        
    async def test_user_login_invalid_credentials(
        self, 
        client: AsyncClient,
        test_user: User
    ):
        """Test login with invalid credentials."""
        login_data = {
            "login_identifier": test_user.email,
            "password": "wrong_password"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == 401
        data = response.json()
        assert "invalid" in data["detail"].lower()

class TestUserEndpoints:
    """Test user management endpoints."""
    
    async def test_get_user_profile(
        self, 
        client: AsyncClient,
        test_user: User,
        auth_headers: dict
    ):
        """Test getting user profile."""
        response = await client.get(
            f"/api/users/{test_user.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == test_user.id
        assert data["email"] == test_user.email
        assert data["full_name"] == test_user.full_name
        
    async def test_update_user_profile(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict
    ):
        """Test updating user profile."""
        update_data = {
            "full_name": "Updated Name",
            "phone_number": "+1999888777"
        }
        
        response = await client.put(
            f"/api/users/{test_user.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
        assert data["phone_number"] == "+1999888777"
        
    async def test_get_user_unauthorized(self, client: AsyncClient, test_user: User):
        """Test accessing user profile without authentication."""
        response = await client.get(f"/api/users/{test_user.id}")
        
        assert response.status_code == 401

class TestWorkflowEndpoints:
    """Test workflow management endpoints."""
    
    async def test_create_workflow(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict,
        sample_workflow_data: dict
    ):
        """Test creating a new workflow."""
        response = await client.post(
            "/api/workflows/",
            json=sample_workflow_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == sample_workflow_data["name"]
        assert data["user_id"] == test_user.id
        assert data["is_active"] is True
        
    async def test_get_user_workflows(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict
    ):
        """Test getting user's workflows."""
        response = await client.get(
            "/api/workflows/",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        
    async def test_update_workflow(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict,
        sample_workflow_data: dict
    ):
        """Test updating a workflow."""
        # First create a workflow
        create_response = await client.post(
            "/api/workflows/",
            json=sample_workflow_data,
            headers=auth_headers
        )
        workflow_id = create_response.json()["id"]
        
        # Update the workflow
        update_data = {
            "name": "Updated Workflow Name",
            "description": "Updated description"
        }
        
        response = await client.put(
            f"/api/workflows/{workflow_id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Workflow Name"
        assert data["description"] == "Updated description"

class TestSessionEndpoints:
    """Test communication session endpoints."""
    
    async def test_create_session(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict,
        sample_session_data: dict
    ):
        """Test creating a new communication session."""
        response = await client.post(
            "/api/sessions/",
            json=sample_session_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["phone_number"] == sample_session_data["phone_number"]
        assert data["user_id"] == test_user.id
        assert data["status"] == "pending"
        
    async def test_get_user_sessions(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict
    ):
        """Test getting user's sessions."""
        response = await client.get(
            "/api/sessions/",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        
    async def test_get_session_details(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict,
        sample_session_data: dict
    ):
        """Test getting session details."""
        # First create a session
        create_response = await client.post(
            "/api/sessions/",
            json=sample_session_data,
            headers=auth_headers
        )
        session_id = create_response.json()["id"]
        
        # Get session details
        response = await client.get(
            f"/api/sessions/{session_id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == session_id
        assert data["phone_number"] == sample_session_data["phone_number"]

class TestHealthEndpoints:
    """Test system health endpoints."""
    
    async def test_health_check(self, client: AsyncClient):
        """Test health check endpoint."""
        response = await client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert "services" in data
        
    async def test_root_endpoint(self, client: AsyncClient):
        """Test root endpoint."""
        response = await client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "status" in data
        assert "version" in data