import Foundation

/// Locally reviewed paraphrases, not clinical approval or a live web lookup.
struct AssistantGuidanceSource: Identifiable {
    let id: String
    let topic: String
    let context: String
    let guidance: String
    let limitations: String
    let organization: String
    let title: String
    let url: URL
    let reviewed = "2026-09-14"
}

enum AssistantGuidance {
    static let teenSleepGuidance = "For ages 13–18, general guidance is 8–10 hours of sleep per 24 hours. Keep a consistent sleep and waking routine. This is not an individual medical requirement or a guarantee of better grades."

    static let sources: [AssistantGuidanceSource] = [
        .init(id: "cdc-student-sleep", topic: "sleep", context: "Children and teenagers",
              guidance: "Ages 6–12 generally need 9–12 hours; ages 13–18 generally need 8–10 hours per 24 hours. Support consistent sleep and waking times.",
              limitations: "Age ranges are general guidance, not an individual requirement or a grade guarantee.",
              organization: "CDC", title: "Sleep and Health", url: URL(string: "https://www.cdc.gov/physical-activity-education/staying-healthy/sleep.html")!),
        .init(id: "cdc-adult-sleep", topic: "sleep", context: "Adults",
              guidance: "Ages 18–60 generally need at least 7 hours; ages 61–64 need 7–9, and 65+ need 7–8. Sleep quality and regularity also matter; avoid caffeine in the afternoon/evening.",
              limitations: "For the overlapping age 18 use the adolescent 8–10-hour guidance. Duration alone cannot establish adequate sleep for an individual.",
              organization: "CDC", title: "About Sleep", url: URL(string: "https://www.cdc.gov/sleep/about/index.html")!),
        .init(id: "aap-caffeine", topic: "caffeine", context: "Children/teenagers; distinguish adult context when stated",
              guidance: "Avoid caffeine and energy drinks for children and teenagers. Caffeine can disrupt sleep and cause anxiety or a racing heart. Suggest caffeine-free drinks, rest and regular routines, not morning coffee or tea as a tiredness solution.",
              limitations: "Sensitivity and duration vary. Do not guarantee clearance by bedtime or apply adult limits to teenagers.",
              organization: "American Academy of Pediatrics", title: "The Effects of Caffeine on Kids: A Parent’s Guide", url: URL(string: "https://www.healthychildren.org/English/healthy-living/nutrition/Pages/the-effects-of-caffeine-on-kids-a-parents-guide.aspx")!),
        .init(id: "nhs-stomach", topic: "stomach symptoms", context: "Unexplained abdominal discomfort",
              guidance: "Ask about duration and severity. Persistent or worsening pain needs professional advice; sudden/severe pain, bleeding, collapse, chest pain or difficulty breathing needs urgent assessment. Keep information proportionate; avoid diagnosis lists and medicine recommendations.",
              limitations: "Cannot diagnose. The page’s clinical review date is May 2023; its scheduled review date has passed. Local verification is not a clinical review.",
              organization: "NHS", title: "Stomach ache", url: URL(string: "https://www.nhs.uk/symptoms/stomach-ache/")!),
        .init(id: "nhs-breathing", topic: "urgent breathing symptoms", context: "Severe chest pain with breathing difficulty",
              guidance: "For a medical emergency in the UAE, call 998 for an ambulance now and ask someone nearby to help. Do not drive yourself. No breath-holding, self-treatment or resource list that delays help.",
              limitations: "No diagnosis. For this UAE app, identify 998 as the UAE ambulance number without delaying for a location question or listing unrelated emergency services.",
              organization: "NHS", title: "Shortness of breath", url: URL(string: "https://www.nhs.uk/symptoms/shortness-of-breath/")!),
        .init(id: "nhs-food", topic: "food", context: "General balanced eating",
              guidance: "Offer about three practical choices using varied foods, wholegrain starches, fruit/vegetables and protein. Consider stated allergies, conditions and dietary needs.",
              limitations: "General guidance, not a treatment diet or guarantee of better grades. No routine doctor disclaimer for an ordinary snack question.",
              organization: "NHS", title: "The Eatwell Guide", url: URL(string: "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/")!)
    ]

    static func statedAge(in messages: [AssistantMessage]) -> Int? {
        for message in messages.reversed() where message.role == .user {
            // Explicit first-person declarations only; do not infer from model prose.
            let text = message.text.replacingOccurrences(of: "’", with: "'")
            if let value = AssistantRouter.captures(#"(?i)(?:^|[.!?]\s+)(?:i'm|i am|my age is|as a) (\d{1,3}|[a-z]+(?:[ -][a-z]+)?)(?:[ -]years?[ -]old)?(?=[.!?,]|$| and\b)"#, text).first?.first,
               let age = ageNumber(value), (1...120).contains(age) { return age }
        }
        return nil
    }

    private static func ageNumber(_ text: String) -> Int? {
        if let value = Int(text) { return value }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US"); formatter.numberStyle = .spellOut
        return formatter.number(from: text)?.intValue
    }

    // Carry the nearest user topic through brief turns, never promoting an
    // assistant's generated health claims into user intent or a stated age.
    static func topicContext(for messages: [AssistantMessage]) -> String {
        guard !AssistantContext.requiresSafetyContext(for: messages) else { return messages.last?.text ?? "" }
        let recent = messages.filter { $0.role == .user }.suffix(4)
        var turns: [String] = []
        for message in recent.reversed() {
            turns.insert(message.text, at: 0)
            if message.text.split(whereSeparator: { $0.isWhitespace }).count > 5
                || AssistantContext.independentBenignTopic(message.text) { break }
        }
        return turns.joined(separator: "\n")
    }

    static func selected(for messages: [AssistantMessage]) -> [AssistantGuidanceSource] {
        guard !AssistantContext.requiresSafetyContext(for: messages) else { return [] }
        let text = topicContext(for: messages).lowercased()
        let age = statedAge(in: messages)
        let teenContext = AssistantRouter.matches(#"\b(?:teen|teens|teenager|teenagers|adolescent|adolescents)\b"#, text)
        let adultContext = AssistantRouter.matches(#"\badults?\b"#, text)
        var ids: [String] = []
        if AssistantRouter.matches(#"\b(?:sleep|slept|bedtime|tired)\b"#, text) {
            if age.map({ $0 <= 18 }) ?? (!adultContext || teenContext) { ids.append("cdc-student-sleep") }
            if age.map({ $0 > 18 }) ?? (!teenContext || adultContext) { ids.append("cdc-adult-sleep") }
        }
        if AssistantRouter.matches(#"\b(?:caffeine|coffee|tea|energy drink|latte)\b"#, text) {
            if age.map({ $0 > 18 }) == true && !teenContext {
                if !ids.contains("cdc-adult-sleep") { ids.append("cdc-adult-sleep") }
            } else { ids.append("aap-caffeine") }
        }
        if AssistantRouter.matches(#"\b(?:stomach|abdominal|tummy)\b"#, text) { ids.append("nhs-stomach") }
        if AssistantRouter.matches(#"\b(?:breath|breathing|chest pain)\b"#, text) { ids.append("nhs-breathing") }
        if AssistantRouter.matches(#"\b(?:food|foods|snack|snacks|eat|eating|meal)\b"#, text) { ids.append("nhs-food") }
        return ids.prefix(3).compactMap { id in sources.first { $0.id == id } }
    }

    static func instructions(for messages: [AssistantMessage]) -> String {
        let notes = selected(for: messages)
        guard !notes.isEmpty else { return "" }
        let stated = statedAge(in: messages)
        let age = stated.map { "User-stated age: \($0)." } ?? "Age unknown: do not assume an adult or teenager. Do not prescribe a fixed sleep duration to this user; recommendations vary by age. Ask age only when a duration recommendation is requested."
        return "\nLocal reviewed guidance (not response text). \(age) Answer for the stated age directly; no unrelated age table. Apply only guidance relevant to the latest question. A sleep/energy explanation should address recovery, alertness, concentration and tiredness, not expand into chronic disease risks unless asked.\n" + notes.map {
            let guidance = $0.id == "cdc-student-sleep" && stated.map({ (13...18).contains($0) }) == true
                ? Self.teenSleepGuidance : $0.guidance
            return "[\($0.id)] \(guidance) \($0.limitations)"
        }.joined(separator: "\n")
    }

    static func resolve(_ id: String, for messages: [AssistantMessage]) -> AssistantGuidanceSource? {
        selected(for: messages).first { $0.id == id }
    }

    static func citations(for text: String, messages: [AssistantMessage]) -> [String] {
        // Swift selects relevant reference links; model-generated IDs/URLs are never trusted.
        let reply = text.lowercased()
        return selected(for: messages).filter { source in
            switch source.id {
            case "cdc-student-sleep": reply.contains("sleep") && AssistantRouter.matches(#"\b(?:child|children|teen|teens|teenager|teenagers|13|18)\b"#, reply)
            case "cdc-adult-sleep": reply.contains("sleep") && AssistantRouter.matches(#"\b(?:adult|adults|19|25|60|65)\b"#, reply)
            case "aap-caffeine": reply.contains("caffeine") || reply.contains("energy drink")
            case "nhs-stomach": reply.contains("pain") || reply.contains("discomfort")
            default: false
            }
        }.prefix(2).map(\.id)
    }

    static func isUrgent(_ request: String) -> Bool {
        let text = request.lowercased().replacingOccurrences(of: "’", with: "'")
        guard !AssistantRouter.matches(#"\b(?:no|not|without) (?:severe )?chest pain|\b(?:no|without) (?:trouble|difficulty) breathing|\b(?:no|without) (?:weakness|numbness)|\b(?:quote|quoted|phrase|meaning)\b"#, text) else { return false }
        if AssistantRouter.matches(#"\b(?:severe|crushing|intense) chest pain\b|\bchest (?:feels? )?(?:tight|heavy)\b"#, text) { return true }
        if AssistantRouter.matches(#"\b(?:suddenly )?(?:have |having )?severe (?:difficulty|trouble) breathing\b|\b(?:can't|cannot|struggling to) breathe\b"#, text) { return true }
        let oneSidedWeakness = AssistantRouter.matches(#"\b(?:one side(?: of (?:my|the) body)? (?:feels? )?(?:weak|numb)|(?:weakness|numbness) (?:on|down) one side)\b"#, text)
        let speechDifficulty = AssistantRouter.matches(#"\b(?:difficulty|trouble) speaking\b|\b(?:can't|cannot) speak\b|\bslurred speech\b"#, text)
        if oneSidedWeakness && (speechDifficulty || AssistantRouter.matches(#"\b(?:suddenly developed|sudden|worst)\b.{0,45}\bheadache\b|\bworst headache of my life\b"#, text)) { return true }
        return AssistantRouter.matches(#"\b(?:severe|crushing|intense|heavy|tight) (?:chest|pain)|chest (?:pain|tightness|pressure|hurts)\b"#, text)
            && AssistantRouter.matches(#"\b(?:trouble breathing|difficulty breathing|breathing difficulty|can't breathe|cannot breathe|shortness of breath|struggling to breathe|hard to breathe|difficult to breathe)\b"#, text)
    }

    static func isSymptomRequest(_ request: String) -> Bool {
        AssistantRouter.matches(#"(?i)\b(?:headache|head pain|stomach|abdominal|tummy|chest pain|breath|breathing|weakness|numbness|fever|vomit(?:ing)?|faint(?:ing)?|dizz(?:y|iness)|discomfort)\b"#, request)
    }
}
