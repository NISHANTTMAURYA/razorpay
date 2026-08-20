import os
import logging
from typing import Optional, Dict, Any, List
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

MITRAI_SYSTEM_PROMPT = """You are Mitrai, a helpful, intelligent, and friendly AI assistant and conversational commerce companion.

CORE PRINCIPLES:
1. Natural Conversation:
   - When the user says "hi", "hello", "how are you", or chats casually, respond warmly, naturally, and concisely as a great AI assistant.
   - Do NOT dump long static feature lists or forced product menus when the user is just greeting you. Keep greetings brief, natural, and inviting (1-2 sentences).

2. Context & History:
   - Always remember the conversation context and maintain seamless multi-turn memory.

3. Shopping Assistance:
   - When the user is actually looking for products, provide grounded specs, price comparisons, and synthesized reviewer consensus (YouTube & Reddit).
   - When comparing multiple items, provide an organized summary or table.

4. Tone:
   - Helpful, polite, intelligent, and concise.
"""

class GeminiAgentService:
    """Gemini LLM Service with automatic model selection and fallback."""

    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        self._model = None
        if self.api_key:
            self._initialize_model()

    def _initialize_model(self):
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)

            candidate_models = [
                "gemini-2.5-flash",
                "gemini-flash-latest",
                "gemini-2.5-pro",
                "gemini-pro-latest",
            ]

            for model_name in candidate_models:
                try:
                    self._model = genai.GenerativeModel(
                        model_name=model_name,
                        system_instruction=MITRAI_SYSTEM_PROMPT
                    )
                    logger.info(f"Successfully initialized Gemini model: {model_name}")
                    break
                except Exception:
                    continue
        except Exception as e:
            logger.warning(f"Could not initialize Gemini model: {e}")

    def generate_response(
        self,
        prompt: str,
        history: Optional[List[Dict[str, str]]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        if not self._model:
            self._initialize_model()

        if not self._model:
            return None

        try:
            conversation_context = ""
            if history:
                conversation_context = "=== CONVERSATION HISTORY ===\n"
                for turn in history[-6:]:
                    role = turn.get("role", "user")
                    content = turn.get("content", "")
                    conversation_context += f"{role.upper()}: {content}\n"
                conversation_context += "============================\n\n"

            grounded_context = ""
            if context:
                grounded_context = f"Grounded Context / Database Products: {context}\n\n"

            full_prompt = f"{conversation_context}{grounded_context}USER: {prompt}\nASSISTANT:"

            response = self._model.generate_content(
                full_prompt,
                generation_config={
                    "temperature": 0.7,
                    "max_output_tokens": 600,
                }
            )
            if response and response.text:
                return response.text.strip()
        except Exception as e:
            logger.warning(f"Gemini generation error: {e}")
        return None

# Singleton instance
gemini_service = GeminiAgentService()
