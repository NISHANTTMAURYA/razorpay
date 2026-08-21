from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch
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

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_agent_engine_search_emits_steps(self, mock_llm):
        mock_llm.return_value = "Recommendation with steps."
        result = CommerceAgentEngine.process_message("Show me headphones under 3000")
        self.assertIn("response", result)
        self.assertIn("steps", result)
        self.assertTrue(len(result["steps"]) >= 2)
        step_names = [s["step_name"] for s in result["steps"]]
        self.assertTrue(any("Intent" in s for s in step_names))
        self.assertIn("Merchant API Gateway Search", step_names)

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_agent_chat_view_endpoint(self, mock_llm):
        mock_llm.return_value = "Recommendation response."
        url = reverse('agent_chat')
        response = self.client.post(url, {"message": "best phone under 30k"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("response", response.data)
        self.assertIn("steps", response.data)

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_agent_stream_chat_view_endpoint(self, mock_llm):
        mock_llm.return_value = "Comparison streaming."
        url = reverse('agent_stream_chat')
        response = self.client.post(url, {"message": "compare boat with sony"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/event-stream')

    def test_agent_watch_product_intent(self):
        result = CommerceAgentEngine.process_message("Alert me when boAt headphones price drops under 1800")
        self.assertEqual(result["intent"], "WATCH_PRODUCT")
        self.assertIn("Radar Alert Activated", result["response"])

    def test_category_detection_and_typo_tolerance(self):
        """Verify that typo-tolerant category detection properly matches smartphones and other categories."""
        from commerce.merchant_clients import merchant_gateway

        # Test typo: "phonea"
        results_typo = merchant_gateway.search_all_merchants(query="find me best phonea under 50k", category="Smartphones")
        self.assertTrue(len(results_typo) > 0)
        self.assertTrue(all(p["category"]["name"] == "Smartphones" for p in results_typo))

        # Test typo: "fone"
        results_fone = merchant_gateway.search_all_merchants(query="best fone under 30000", category="Smartphones")
        self.assertTrue(len(results_fone) > 0)
        self.assertTrue(all(p["category"]["name"] == "Smartphones" for p in results_fone))

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_phone_query_returns_smartphones_not_unrelated_items(self, mock_llm):
        """Verify agent returns smartphones when user searches for phones, not coffee or body scrub."""
        mock_llm.return_value = "### Recommendation\n- Product: OnePlus Nord\n- Value: High"
        result = CommerceAgentEngine.process_message("find me best phonea under 50k")
        self.assertEqual(result["intent"], "SEARCH_RECOMMEND")
        products = result.get("products", [])
        self.assertTrue(len(products) > 0, "Should return at least one product")
        for prod in products:
            cat_name = prod.get("category", "")
            if isinstance(cat_name, dict):
                cat_name = cat_name.get("name", "")
            self.assertIn(cat_name, ["Smartphones", "Electronics", "Audio"], f"Unexpected category {cat_name} for phone query")

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_no_hardcoded_reviewer_or_channel_names(self, mock_llm):
        """Ensure no hardcoded reviewer names or subreddit names exist in agent responses or step metadata."""
        mock_llm.return_value = "Verified product with dynamic video reviews and community threads."
        forbidden_terms = [
            "geekyranjit", "mkbhd", "techburner", "dave2d", "beebom", "unbox therapy",
            "r/indiatech", "r/gadgets", "amazon, flipkart, blinkit & zepto"
        ]

        result = CommerceAgentEngine.process_message("best phone under 40k")
        response_text = result.get("response", "").lower()
        steps = result.get("steps", [])

        # Check response text
        for term in forbidden_terms:
            self.assertNotIn(term, response_text, f"Forbidden hardcoded term '{term}' found in response!")

        # Check step metadata
        for step in steps:
            step_str = str(step).lower()
            for term in forbidden_terms:
                self.assertNotIn(term, step_str, f"Forbidden hardcoded term '{term}' found in step metadata!")

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_connected_merchants_queried_is_dynamic(self, mock_llm):
        """Verify connected_merchants_queried in step metadata reflects the live count of merchant clients."""
        mock_llm.return_value = "Recommendation based on merchant inventory."
        from commerce.merchant_clients import merchant_gateway
        expected_count = len(merchant_gateway.clients)

        result = CommerceAgentEngine.process_message("find me running shoes under 5000")
        steps = result.get("steps", [])
        merchant_step = next((s for s in steps if s.get("step_name") == "Merchant API Gateway Search"), None)

        self.assertIsNotNone(merchant_step, "Merchant API Gateway Search step should exist")
        details = merchant_step.get("details", {})
        self.assertEqual(details.get("connected_merchants_queried"), expected_count)

    @patch('agent.llm_service.gemini_service.generate_response')
    def test_multi_turn_chat_history_context_inheritance(self, mock_llm):
        """Verify that follow-up turns inherit category context from chat history."""
        mock_llm.return_value = "Here are the camera and battery specs for the smartphone."

        history = [
            {"role": "user", "content": "find me best smartphones under 30000"},
            {"role": "assistant", "content": "I recommend the Redmi Note 13 Pro and OnePlus Nord CE 3 Lite."}
        ]

        # Follow-up search query without naming category explicitly
        result = CommerceAgentEngine.process_message(
            message="show me cheaper options under 25000",
            history=history
        )

        self.assertEqual(result["intent"], "SEARCH_RECOMMEND")
        products = result.get("products", [])
        self.assertTrue(len(products) > 0, "Should return smartphone products using history context")
        for prod in products:
            cat_name = prod.get("category", "")
            if isinstance(cat_name, dict):
                cat_name = cat_name.get("name", "")
            self.assertIn(cat_name, ["Smartphones", "Electronics", "Audio"])

    def test_comparison_resolves_products_from_history(self):
        """Verify comparison node extracts compared items from multi-turn history when user says 'compare them'."""
        history = [
            {"role": "user", "content": "show me boAt Rockerz and Sony headphones"},
            {"role": "assistant", "content": "Here are the boAt Rockerz 550 and Sony WH-CH520."}
        ]

        result = CommerceAgentEngine.process_message(
            message="compare them side by side",
            history=history
        )

        self.assertEqual(result["intent"], "COMPARE")
        self.assertIsNotNone(result.get("comparison"))
        comp_data = result["comparison"]
        self.assertTrue(len(comp_data.get("columns", [])) >= 3)
        self.assertTrue(len(comp_data.get("rows", [])) >= 4)

    def test_review_followup_intent_and_memory(self):
        """Verify that follow-up review inquiries on existing comparisons route to REVIEW_FOLLOWUP and retain products."""
        history = [
            {"role": "user", "content": "compare oppo reno 16c and motorola edge pro plus"},
            {"role": "assistant", "content": "### ⚖️ Side-by-Side Product Comparison: Oppo Reno 16c 5G vs Motorola Edge 70 Pro+ 5G\n\n**🏆 Executive Verdict: Which is Better?**\nThe Motorola Edge is better..."}
        ]

        result = CommerceAgentEngine.process_message(
            message="now search reddit reviews of both",
            history=history
        )

        self.assertEqual(result["intent"], "REVIEW_FOLLOWUP")
        self.assertIn("response", result)
        self.assertTrue(len(result["response"]) > 20)



