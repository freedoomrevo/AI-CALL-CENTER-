"""
Subscriptions router
The Scribe's Service Tiers
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List

from database.connection import get_database
from models.user import User
from models.subscription import SubscriptionTier
from routers.auth import get_current_user
from services.manual_payment_service import ManualPaymentService
from services.payment_monitoring_service import PaymentMonitoringService

router = APIRouter()

class SubscriptionTierResponse(BaseModel):
    id: int
    name: str
    price_usd: float
    context_limit: int
    description: str

class PaymentInitiation(BaseModel):
    tier_id: int

class PaymentMonitoringRequest(BaseModel):
    tier_id: int
    bank_card_number: str

@router.get("/tiers", response_model=List[SubscriptionTierResponse])
async def get_subscription_tiers(
    db: AsyncSession = Depends(get_database)
):
    """
    Get available subscription tiers
    The Scribe's Service Offerings
    """
    try:
        result = await db.execute(
            select(SubscriptionTier).order_by(SubscriptionTier.price_usd)
        )
        tiers = result.scalars().all()
        
        return [
            SubscriptionTierResponse(
                id=tier.id,
                name=tier.name,
                price_usd=float(tier.price_usd),
                context_limit=tier.context_limit,
                description=tier.description
            )
            for tier in tiers
        ]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to get subscription tiers")

@router.post("/initiate-payment")
async def initiate_payment(
    payment_data: PaymentInitiation,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_database)
):
    """
    Initiate payment for subscription tier
    The Scribe's Financial Gateway
    """
    try:
        # Get tier information
        tier_result = await db.execute(
            select(SubscriptionTier).where(SubscriptionTier.id == payment_data.tier_id)
        )
        tier = tier_result.scalar_one_or_none()
        
        if not tier:
            raise HTTPException(status_code=404, detail="Subscription tier not found")
        
        # Initiate manual payment
        payment_service = ManualPaymentService()
        result = await payment_service.initiate_consultation_payment(
            user_id=current_user.id,
            tier_name=tier.name,
            tier_price_usd=float(tier.price_usd),
            company_number=current_user.company_number
        )
        
        if result["success"]:
            return {
                "success": True,
                "payment_id": result["payment_id"],
                "reference_code": result["reference_code"],
                "amount_uzs": result["amount_uzs"],
                "expires_at": result["expires_at"],
                "payment_instructions": result["payment_instructions"],
                "bank_details": result["bank_details"],
                "tier_name": tier.name
            }
        else:
            raise HTTPException(status_code=500, detail=result["error"])
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to initiate payment")

@router.post("/start-payment-monitoring")
async def start_payment_monitoring(
    payment_data: PaymentMonitoringRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_database)
):
    """
    Start payment monitoring with 30-minute timer
    The Scribe's Payment Watcher Activation
    """
    try:
        # Get tier information
        tier_result = await db.execute(
            select(SubscriptionTier).where(SubscriptionTier.id == payment_data.tier_id)
        )
        tier = tier_result.scalar_one_or_none()
        
        if not tier:
            raise HTTPException(status_code=404, detail="Subscription tier not found")
        
        if not current_user.company_number:
            raise HTTPException(status_code=400, detail="User has no assigned company number")
        
        # Calculate amounts
        amount_usd = float(tier.price_usd)
        amount_uzs = int(amount_usd * 12300)  # USD to UZS conversion
        
        # Start payment monitoring
        monitoring_service = PaymentMonitoringService()
        result = await monitoring_service.start_payment_monitoring(
            user_id=current_user.id,
            subscription_tier_id=tier.id,
            company_number=current_user.company_number,
            bank_card_number=payment_data.bank_card_number,
            amount_usd=amount_usd,
            amount_uzs=amount_uzs,
            db=db
        )
        
        return {
            "success": True,
            "message": "Payment monitoring started. Transfer money to the specified card and we'll monitor for confirmation SMS.",
            "monitoring_session": result,
            "tier_name": tier.name,
            "instructions": f"Transfer {amount_uzs:,} UZS to card {payment_data.bank_card_number} with reference {result['reference_code']}"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to start payment monitoring")

@router.get("/payment-monitoring-status")
async def get_payment_monitoring_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_database)
):
    """
    Get current payment monitoring status
    The Scribe's Payment Status Check
    """
    try:
        monitoring_service = PaymentMonitoringService()
        session = await monitoring_service.get_active_payment_session(current_user.id, db)
        
        if session:
            return {
                "has_active_session": True,
                "session": session
            }
        else:
            return {
                "has_active_session": False,
                "session": None
            }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to get payment monitoring status")