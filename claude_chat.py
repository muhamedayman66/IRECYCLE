from poe_api_wrapper import PoeApi

# كوكيز الدخول من متصفحك
cookies = {
    "p-b": "aPrCw80WID-F4ZQm2p6gqg%3D%3D",
    "p-lat": "UPW%2F%2B1oWoBEGTftVeuWYTAhMwzrnvgwz5W%2FVoniZ%2FA%3D%3D"
}

client = PoeApi(cookies)

bot = "a2"  # Claude 3 Opus

while True:
    prompt = input("أنت: ")
    if prompt.lower() in ["exit", "quit"]:
        break
    print("Claude: ", end="")
    for chunk in client.send_message(bot, prompt):
        print(chunk["text"], end="")
    print("\n" + "-" * 50)
