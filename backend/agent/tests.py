from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from commerce.models import Merchant, Category, Product
from .agent_tracer import AgentExecutionTracer
from .services import CommerceAgentEngine

class AgentTracerAndEngineTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.merchant = Merchant.objects.create(
            name="Direct Brand Store",
            slug="direct-brand",
            description="Premium Direct Store"
        )
        self.category = Category.objects.create(
            name="Audio & Headphones",
            slug="audio-headphones"
        )
        self.product = Product.objects.create(
            merchant=self.merchant,
            category=self.category,
            name="boAt Rockerz 550",
            brand="boAt",
            price=1999.00,
            original_price=4999.00,
            rating=4.6,
            review_count=1240,
            attributes={"battery_life": "20 Hours"}
        )

    def test_agent_tracer_lifecycle(self):
        tracer = AgentExecutionTracer()
        step = tracer.start_step("Testing Step", "Description of test", tool_name="test_tool")
        self.assertEqual(step.status, "RUNNING")
        step.complete({"result": "success"})
        self.assertEqual(step.status, "COMPLETED")
        self.assertTrue(step.duration_ms >= 0)

        data = tracer.get_steps_data()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["step_name"], "Testing Step")
        self.assertEqual(data[0]["status"], "COMPLETED")

    def test_agent_engine_search_emits_steps(self):
        result = CommerceAgentEngine.process_message("Show me headphones under 3000")
        self.assertIn("response", result)
        self.assertIn("steps", result)
        self.assertTrue(len(result["steps"]) >= 2)
        step_names = [s["step_name"] for s in result["steps"]]
        self.assertIn("Intent Understanding", step_names)
        self.assertIn("Catalog Search & Extraction", step_names)

    def test_agent_chat_view_endpoint(self):
        url = reverse('agent_chat')
        response = self.client.post(url, {"message": "best phone under 30k"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("response", response.data)
        self.assertIn("steps", response.data)

    def test_agent_stream_chat_view_endpoint(self):
        url = reverse('agent_stream_chat')
        response = self.client.post(url, {"message": "compare boat with sony"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/event-stream')

    def test_agent_watch_product_intent(self):
        result = CommerceAgentEngine.process_message("Alert me when boAt headphones price drops under 1800")
        self.assertEqual(result["intent"], "WATCH_PRODUCT")
        self.assertIn("Radar Alert Activated", result["response"])

