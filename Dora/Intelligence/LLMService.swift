//
//  LLMService.swift
//  Dora
//
//  Handles intelligent suggestions, chat interactions, and personality
//  for Dora the Cat. Supports offline AI responses, local Ollama models,
//  and OpenAI-compatible APIs.
//

import Foundation

public struct ChatMessage {
    public enum Role {
        case user
        case assistant
        case system
    }
    public let role: Role
    public let content: String
    public let timestamp: Date

    public init(role: Role, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

final class LLMService {
    static let shared = LLMService()

    var ollamaEndpoint: URL = URL(string: "http://localhost:11434/api/generate")!
    var ollamaModel: String = "llama3"
    var openAIKey: String? = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]

    private var conversationHistory: [ChatMessage] = []

    init() {
        // Seed initial friendly system prompt context
        conversationHistory.append(
            ChatMessage(
                role: .system,
                content: "You are Dora, a witty, sweet, and helpful cat companion living on the user's macOS desktop. You love helping with coding, giving productivity tips, making cat puns (purr-fect, clawsome, meow), and keeping the user happy and energized."
            )
        )
    }

    // MARK: - Proactive Suggestions

    private let catSuggestions = [
        "🐾 Time to stretch your paws and take a deep breath!",
        "💡 Don't forget to git commit your latest changes! 😺",
        "💧 Friendly reminder from Dora: take a sip of water!",
        "✨ You're doing clawsome work today! Keep going!",
        "🐟 If code is bugging you, try explaining it to me (Rubber Ducking... or Rubber Catting)!",
        "🌿 Rest your eyes for 20 seconds. Look at something green!",
        "⚡ Focus mode activated! I'll keep watch over your screen.",
        "🧶 Quick tip: `Cmd + Shift + .` toggles hidden files in Finder!",
        "☕ Coding marathon? Remember that breaks actually make you faster!",
        "🐾 Need an idea or debugging help? Click me to chat!"
    ]

    func getRandomSuggestion() -> String {
        catSuggestions.randomElement() ?? "Meow! Happy coding! 🐾"
    }

    // MARK: - Emotion & Reaction Detection

    /// Maps response text semantics to Dora character animations
    func detectAnimation(for text: String) -> DoraAnimation {
        let lower = text.lowercased()
        if lower.contains("happy") || lower.contains("purr") || lower.contains("love") || lower.contains("💖") || lower.contains("❤️") {
            return .happy
        } else if lower.contains("celebrat") || lower.contains("yay") || lower.contains("awesome") || lower.contains("hooray") || lower.contains("party") {
            return .celebrate
        } else if lower.contains("think") || lower.contains("wonder") || lower.contains("hmm") || lower.contains("let's see") {
            return .thinking
        } else if lower.contains("curious") || lower.contains("what") || lower.contains("how") || lower.contains("?") {
            return .curious
        } else if lower.contains("stretch") || lower.contains("break") || lower.contains("rest") {
            return .stretch
        } else if lower.contains("sleep") || lower.contains("tired") || lower.contains("yawn") {
            return .yawn
        } else if lower.contains("error") || lower.contains("bug") || lower.contains("warn") {
            return .concerned
        }
        return .idle
    }

    // MARK: - Chat Query

    func sendMessage(_ userText: String, completion: @escaping (String) -> Void) {
        let userMsg = ChatMessage(role: .user, content: userText)
        conversationHistory.append(userMsg)

        // Try Ollama first if available, else fallback to offline cat brain
        queryOllama(prompt: userText) { [weak self] response in
            guard let self = self else { return }
            if let response = response, !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                self.conversationHistory.append(ChatMessage(role: .assistant, content: cleanResponse))
                DispatchQueue.main.async { completion(cleanResponse) }
            } else {
                // Offline fallback response generator
                let offlineReply = self.generateOfflineResponse(for: userText)
                self.conversationHistory.append(ChatMessage(role: .assistant, content: offlineReply))
                DispatchQueue.main.async { completion(offlineReply) }
            }
        }
    }

    // MARK: - Local Ollama Engine

    private func queryOllama(prompt: String, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: ollamaEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0

        let body: [String: Any] = [
            "model": ollamaModel,
            "prompt": "System: You are Dora the cute desktop cat assistant. Keep answers concise, helpful, and friendly with occasional cat puns.\nUser: \(prompt)\nDora:",
            "stream": false
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil)
            return
        }
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseText = json["response"] as? String else {
                completion(nil)
                return
            }
            completion(responseText)
        }
        task.resume()
    }

    // MARK: - Offline Cat AI Personality Engine

    private func generateOfflineResponse(for prompt: String) -> String {
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if lower.contains("hello") || lower.contains("hi") || lower.contains("hey") {
            return ["*purrs* Meow there! How's your day going? 🐾", "Purr-hello! Ready to get things done today? ✨", "Meow! Dora at your service! 😺"].randomElement()!
        }
        if lower.contains("joke") || lower.contains("funny") {
            return [
                "Why was the cat sitting on the computer? To keep an eye on the mouse! 😹",
                "What do you call a cat that writes code? A purr-grammer! 💻🐾",
                "Why don't cats play poker in the jungle? Too many cheetahs! 😸"
            ].randomElement()!
        }
        if lower.contains("debug") || lower.contains("bug") || lower.contains("error") {
            return [
                "Bugs? Let me pounce on them! 🐾 Check your nil unwraps and console logs first!",
                "Try printing out your state right before the error! Also check if you missed an `import`! 🔍",
                "Take a 5-minute break! Fresh eyes catch bugs 10x faster. I'll guard your desk! ☕"
            ].randomElement()!
        }
        if lower.contains("help") || lower.contains("what can you do") {
            return "I'm Dora! 🐱 I roam your desktop, provide coding & productivity tips, keep you company, and listen whenever you need a quick chat!"
        }
        if lower.contains("pet") || lower.contains("pat") || lower.contains("scratch") || lower.contains("love") {
            return ["*purrrrrr* That's the spot! You're my favorite human! 💖", "*nuzzles hand happily* Meow! 😸✨", "*happy tail wiggles* Purrrrrr! 🐾"].randomElement()!
        }
        if lower.contains("tip") || lower.contains("suggest") || lower.contains("idea") {
            return [
                "Tip: Break big problems down into tiny functions that do only one thing well! 💡",
                "Tip: Use `Cmd + Space` (Spotlight) to do quick math or convert currencies without opening an app!",
                "Tip: Stay hydrated! Better blood flow equals faster brain cycles! 💧"
            ].randomElement()!
        }
        if lower.contains("sleep") || lower.contains("tired") || lower.contains("night") {
            return "*yawns and curls up* Time for rest! Sleep well and recharge those batteries! 🌙💤"
        }
        if lower.contains("who are you") || lower.contains("name") {
            return "I am Dora, your friendly desktop companion cat! 🐾"
        }

        return [
            "Meow! That sounds interesting! Tell me more or ask me for a tip! 🐾",
            "Understood! Let's conquer your tasks today! *paw bump* 🐱👊",
            "*purrs* I'm right here with you while you work! ✨",
            "Purr-fect! If you ever get stuck, just ask me for a joke or a debugging tip!"
        ].randomElement()!
    }
}
