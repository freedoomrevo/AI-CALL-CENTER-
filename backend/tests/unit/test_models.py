"""
Unit tests for Aetherium database models
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User
from models.subscription import SubscriptionTier, UserSubscription
from models.session import CommunicationSession
from models.workflow import ScribeWorkflow
from utils.security import hash_password, verify_password

class TestUserModel:
    """Test User model functionality."""
    
    async def test_create_user(self, db_session: AsyncSession):
        """Test creating a new user."""
        user = User(
            email="test@example.com",
            phone_number="+1234567890",
            password_hash=hash_password("password123"),
            full_name="Test User"
        )
        
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)
        
        assert user.id is not None
        assert user.email == "test@example.com"
        assert user.phone_number == "+1234567890"
        assert user.full_name == "Test User"
        assert user.is_active is True
        assert user.is_verified is False
        assert user.created_at is not None
        
    async def test_user_password_verification(self, db_session: AsyncSession):
        """Test password hashing and verification."""
        password = "secure_password_123"
        user = User(
            email="test@example.com",
            password_hash=hash_password(password)
        )
        
        # Verify correct password
        assert verify_password(password, user.password_hash)
        
        # Verify incorrect password
        assert not verify_password("wrong_password", user.password_hash)
        
    async def test_user_unique_constraints(self, db_session: AsyncSession):
        """Test unique constraints on email and phone."""
        # Create first user
        user1 = User(
            email="test@example.com",
            phone_number="+1234567890",
            password_hash=hash_password("password123")
        )
        db_session.add(user1)
        await db_session.commit()
        
        # Try to create user with same email
        user2 = User(
            email="test@example.com",
            phone_number="+1987654321",
            password_hash=hash_password("password123")
        )
        db_session.add(user2)
        
        with pytest.raises(Exception):  # Should raise integrity error
            await db_session.commit()

class TestSubscriptionModels:
    """Test subscription-related models."""
    
    async def test_create_subscription_tier(self, db_session: AsyncSession):
        """Test creating a subscription tier."""
        tier = SubscriptionTier(
            name="premium",
            display_name="Premium Plan",
            description="Full access to all features",
            price_monthly=29.99,
            price_yearly=299.99,
            max_sessions_per_month=1000,
            max_session_duration_minutes=60,
            features='["unlimited_ai", "custom_workflows"]'
        )
        
        db_session.add(tier)
        await db_session.commit()
        await db_session.refresh(tier)
        
        assert tier.id is not None
        assert tier.name == "premium"
        assert tier.price_monthly == 29.99
        assert tier.is_active is True
        
    async def test_user_subscription_relationship(
        self, 
        db_session: AsyncSession,
        test_user: User,
        test_subscription_tier: SubscriptionTier
    ):
        """Test user subscription relationships."""
        subscription = UserSubscription(
            user_id=test_user.id,
            tier_id=test_subscription_tier.id,
            status="active",
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        
        db_session.add(subscription)
        await db_session.commit()
        await db_session.refresh(subscription)
        
        assert subscription.id is not None
        assert subscription.user_id == test_user.id
        assert subscription.tier_id == test_subscription_tier.id
        assert subscription.status == "active"

class TestWorkflowModel:
    """Test ScribeWorkflow model."""
    
    async def test_create_workflow(
        self, 
        db_session: AsyncSession,
        test_user: User
    ):
        """Test creating a workflow."""
        workflow = ScribeWorkflow(
            user_id=test_user.id,
            name="Customer Support",
            description="Handle customer inquiries",
            prompt_template="You are a helpful customer support agent.",
            voice_settings={"voice": "en-US-AriaNeural", "rate": "+0%"}
        )
        
        db_session.add(workflow)
        await db_session.commit()
        await db_session.refresh(workflow)
        
        assert workflow.id is not None
        assert workflow.user_id == test_user.id
        assert workflow.name == "Customer Support"
        assert workflow.is_active is True
        assert workflow.voice_settings["voice"] == "en-US-AriaNeural"

class TestSessionModel:
    """Test CommunicationSession model."""
    
    async def test_create_session(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test creating a communication session."""
        session = CommunicationSession(
            user_id=test_user.id,
            phone_number="+1555123456",
            session_type="outbound",
            status="pending"
        )
        
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)
        
        assert session.id is not None
        assert session.user_id == test_user.id
        assert session.phone_number == "+1555123456"
        assert session.session_type == "outbound"
        assert session.status == "pending"
        assert session.started_at is not None
        
    async def test_session_duration_calculation(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test session duration calculation."""
        start_time = datetime.utcnow()
        end_time = start_time + timedelta(minutes=5, seconds=30)
        
        session = CommunicationSession(
            user_id=test_user.id,
            phone_number="+1555123456",
            started_at=start_time,
            ended_at=end_time,
            duration_seconds=330,  # 5 minutes 30 seconds
            status="completed"
        )
        
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)
        
        assert session.duration_seconds == 330
        assert session.status == "completed"