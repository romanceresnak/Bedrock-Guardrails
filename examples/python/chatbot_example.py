"""
Príklad produkčného chatbota s AWS Bedrock Guardrails.

Ukazuje:
1. Konverzačný flow s históriou
2. Integráciu guardrailov do chatbota
3. Error handling a retry logiku
4. Logovanie a monitoring
"""

import boto3
import json
import os
from datetime import datetime
from typing import List, Dict
from dotenv import load_dotenv

load_dotenv()


class GuardedChatbot:
    """
    Produkčný chatbot s integrovanými Bedrock Guardrails.
    """

    def __init__(
        self,
        model_id: str,
        guardrail_id: str,
        guardrail_version: str = '1',
        region: str = 'us-east-1',
        max_history: int = 10
    ):
        self.model_id = model_id
        self.guardrail_id = guardrail_id
        self.guardrail_version = guardrail_version
        self.region = region
        self.max_history = max_history

        self.client = boto3.client('bedrock-runtime', region_name=region)
        self.conversation_history: List[Dict] = []
        self.blocked_attempts = 0

    def chat(self, user_message: str) -> Dict:
        """
        Hlavná metóda pre chatovanie s guardrail ochranou.

        Args:
            user_message: Správa od používateľa

        Returns:
            Dictionary s odpoveďou a metadata
        """
        timestamp = datetime.now().isoformat()

        # Pridanie user message do histórie
        self.conversation_history.append({
            'role': 'user',
            'content': [{'type': 'text', 'text': user_message}]
        })

        try:
            # Príprava requestu
            request_body = {
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 2000,
                'messages': self._get_messages_for_api(),
                'temperature': 0.7
            }

            # Volanie s guardrail
            response = self.client.invoke_model(
                modelId=self.model_id,
                guardrailIdentifier=self.guardrail_id,
                guardrailVersion=self.guardrail_version,
                body=json.dumps(request_body)
            )

            # Parsovanie odpovede
            response_body = json.loads(response['body'].read())
            headers = response.get('ResponseMetadata', {}).get('HTTPHeaders', {})

            guardrail_action = headers.get('x-amzn-bedrock-guardrail-action', 'NONE')

            if guardrail_action == 'BLOCKED':
                self.blocked_attempts += 1
                return self._handle_blocked_response(user_message, timestamp)

            # Extrakcia odpovede
            assistant_message = response_body['content'][0]['text']

            # Pridanie assistant response do histórie
            self.conversation_history.append({
                'role': 'assistant',
                'content': [{'type': 'text', 'text': assistant_message}]
            })

            # Udržiavanie maximálnej dĺžky histórie
            self._trim_history()

            return {
                'success': True,
                'message': assistant_message,
                'timestamp': timestamp,
                'guardrail_action': guardrail_action,
                'usage': response_body.get('usage', {}),
                'blocked': False
            }

        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'timestamp': timestamp,
                'blocked': True
            }

    def _get_messages_for_api(self) -> List[Dict]:
        """Pripraví správy pre API (posledných N správ)."""
        return self.conversation_history[-self.max_history:]

    def _trim_history(self):
        """Udržiava históriu na maximálnej dĺžke."""
        if len(self.conversation_history) > self.max_history * 2:
            # Zachová systémovú správu (ak existuje) + posledných N správ
            self.conversation_history = self.conversation_history[-(self.max_history * 2):]

    def _handle_blocked_response(self, user_message: str, timestamp: str) -> Dict:
        """Spracuje zablokovanú odpoveď."""
        blocked_message = (
            "Prepáčte, ale váš dopyt bol zablokovaný z bezpečnostných dôvodov. "
            "Prosím, preformulujte vašu otázku bez citlivých údajov alebo nevhodného obsahu."
        )

        # Log blocked attempt
        self._log_blocked_attempt(user_message, timestamp)

        # Odstránenie poslednej user správy z histórie
        if self.conversation_history and self.conversation_history[-1]['role'] == 'user':
            self.conversation_history.pop()

        return {
            'success': False,
            'message': blocked_message,
            'timestamp': timestamp,
            'guardrail_action': 'BLOCKED',
            'blocked': True
        }

    def _log_blocked_attempt(self, message: str, timestamp: str):
        """Loguje zablokované pokusy (pre monitoring)."""
        log_entry = {
            'timestamp': timestamp,
            'blocked_attempts_count': self.blocked_attempts,
            'message_preview': message[:100]
        }
        print(f"[BLOCKED] {json.dumps(log_entry, indent=2)}")

    def reset_conversation(self):
        """Resetuje konverzačnú históriu."""
        self.conversation_history = []
        self.blocked_attempts = 0

    def get_conversation_summary(self) -> Dict:
        """Vráti štatistiky o konverzácii."""
        total_messages = len(self.conversation_history)
        user_messages = sum(1 for m in self.conversation_history if m['role'] == 'user')
        assistant_messages = sum(1 for m in self.conversation_history if m['role'] == 'assistant')

        return {
            'total_messages': total_messages,
            'user_messages': user_messages,
            'assistant_messages': assistant_messages,
            'blocked_attempts': self.blocked_attempts
        }


def main():
    """Interaktívna demo chatbot aplikácia."""

    # Konfigurácia
    MODEL_ID = os.getenv('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
    GUARDRAIL_ID = os.getenv('GUARDRAIL_ID')
    GUARDRAIL_VERSION = os.getenv('GUARDRAIL_VERSION', '1')
    REGION = os.getenv('AWS_REGION', 'us-east-1')

    if not GUARDRAIL_ID:
        print("Error: GUARDRAIL_ID not set in .env file")
        return

    # Vytvorenie chatbota
    chatbot = GuardedChatbot(
        model_id=MODEL_ID,
        guardrail_id=GUARDRAIL_ID,
        guardrail_version=GUARDRAIL_VERSION,
        region=REGION
    )

    print("=" * 80)
    print("AWS Bedrock Guarded Chatbot")
    print("=" * 80)
    print(f"Model: {MODEL_ID}")
    print(f"Guardrail: {GUARDRAIL_ID} (v{GUARDRAIL_VERSION})")
    print()
    print("Príkazy:")
    print("  - Napíšte správu pre chat")
    print("  - 'reset' - vymazať históriu")
    print("  - 'stats' - zobraziť štatistiky")
    print("  - 'quit' - ukončiť")
    print("=" * 80)
    print()

    # Hlavný chat loop
    while True:
        try:
            user_input = input("\nVy: ").strip()

            if not user_input:
                continue

            # Spracovanie príkazov
            if user_input.lower() == 'quit':
                print("\nĎakujem za používanie chatbota. Dovidenia!")
                break

            elif user_input.lower() == 'reset':
                chatbot.reset_conversation()
                print("\n✓ Konverzácia bola resetovaná.")
                continue

            elif user_input.lower() == 'stats':
                stats = chatbot.get_conversation_summary()
                print("\n--- Štatistiky ---")
                print(f"Celkom správ: {stats['total_messages']}")
                print(f"Vaše správy: {stats['user_messages']}")
                print(f"Odpovede asistenta: {stats['assistant_messages']}")
                print(f"Zablokované pokusy: {stats['blocked_attempts']}")
                continue

            # Zaslanie správy chatbotovi
            response = chatbot.chat(user_input)

            if response['success']:
                print(f"\nAsistent: {response['message']}")

                # Debug info
                if response.get('usage'):
                    print(f"\n[Debug] Tokeny: {response['usage']}")

            elif response['blocked']:
                print(f"\n⚠️  {response['message']}")

            else:
                print(f"\n❌ Chyba: {response.get('error', 'Neznáma chyba')}")

        except KeyboardInterrupt:
            print("\n\nProgram prerušený. Dovidenia!")
            break
        except Exception as e:
            print(f"\n❌ Neočakávaná chyba: {e}")


if __name__ == "__main__":
    main()
