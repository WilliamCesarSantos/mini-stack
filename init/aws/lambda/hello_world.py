import json


def handler(event, context):
    name = event.get("name", "World")
    message = f"Hello, {name}! 👋 Running on MiniStack Lambda."

    print(f"[lambda] event received: {json.dumps(event)}")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": message}),
    }
