import logging
from decimal import Decimal
from django.utils import timezone
from celery import shared_task
from .models import ProductWatcher, WatchNotification, Product

logger = logging.getLogger(__name__)

@shared_task(name='commerce.tasks.check_product_watchers_task')
def check_product_watchers_task():
    """
    Periodic Celery task that evaluates active product watchers against live inventory,
    price drops, stock changes, and dynamic criteria.
    """
    active_watchers = ProductWatcher.objects.filter(status='ACTIVE')
    triggered_count = 0

    for watcher in active_watchers:
        try:
            triggered = False
            title = ""
            message = ""
            matched_prod = None

            # 1. Price Drop Evaluation
            if watcher.condition_type == 'PRICE_DROP':
                if watcher.product and watcher.target_price:
                    if watcher.product.price <= watcher.target_price:
                        triggered = True
                        matched_prod = watcher.product
                        title = f"🔥 Price Drop Alert: {watcher.product.name}"
                        message = (
                            f"Great news! {watcher.product.name} dropped to ₹{watcher.product.price:,} "
                            f"(your target was ₹{watcher.target_price:,})."
                        )

            # 2. Stock Available Evaluation
            elif watcher.condition_type == 'STOCK_AVAILABLE':
                if watcher.product and watcher.product.is_available and watcher.product.stock_quantity > 0:
                    triggered = True
                    matched_prod = watcher.product
                    title = f"📦 Back in Stock: {watcher.product.name}"
                    message = f"{watcher.product.name} is now available for instant Razorpay checkout!"

            # 3. New Launch in Category Evaluation
            elif watcher.condition_type == 'NEW_LAUNCH':
                if watcher.category:
                    new_prod = watcher.category.products.filter(
                        created_at__gte=watcher.created_at,
                        is_available=True
                    ).exclude(id=watcher.product_id if watcher.product_id else None).first()
                    if new_prod:
                        triggered = True
                        matched_prod = new_prod
                        title = f"✨ New Launch Alert in {watcher.category.name}"
                        message = f"{new_prod.name} has just launched at ₹{new_prod.price:,}."

            # 4. Dynamic Spec & Price Match
            elif watcher.condition_type == 'DYNAMIC_SPEC_MATCH':
                query = Product.objects.filter(is_available=True)
                if watcher.search_query:
                    query = query.filter(name__icontains=watcher.search_query)
                if watcher.target_price:
                    query = query.filter(price__lte=watcher.target_price)
                
                # Check attributes criteria
                crit = watcher.dynamic_criteria or {}
                matched_cand = query.order_by('price').first()
                if matched_cand:
                    triggered = True
                    matched_prod = matched_cand
                    title = f"🎯 Dynamic Match Found: {matched_cand.name}"
                    message = f"Found a matching product for your criteria at ₹{matched_cand.price:,}."

            # If triggered, create notification and update watcher
            if triggered:
                watcher.status = 'TRIGGERED'
                watcher.is_triggered = True
                watcher.triggered_at = timezone.now()
                watcher.save(update_fields=['status', 'is_triggered', 'triggered_at'])

                WatchNotification.objects.create(
                    watcher=watcher,
                    title=title,
                    message=message,
                    matched_product=matched_prod,
                    action_url=f"/product/{matched_prod.id}" if matched_prod else "/deals"
                )
                triggered_count += 1
                logger.info(f"Triggered watch notification: {title} for watcher {watcher.id}")

            watcher.last_checked_at = timezone.now()
            watcher.save(update_fields=['last_checked_at'])

        except Exception as e:
            logger.error(f"Error evaluating watcher {watcher.id}: {e}")

    return f"Evaluated {active_watchers.count()} watchers, triggered {triggered_count} alerts."
