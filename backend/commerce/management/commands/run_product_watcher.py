from django.core.management.base import BaseCommand
from commerce.tasks import check_product_watchers_task

class Command(BaseCommand):
    help = 'Executes the product watch / price drop evaluation cycle'

    def handle(self, *args, **options):
        self.stdout.write("Running Product Watcher cycle...")
        result = check_product_watchers_task()
        self.stdout.write(self.style.SUCCESS(f"Finished: {result}"))
