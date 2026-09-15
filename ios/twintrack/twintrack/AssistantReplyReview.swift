import Foundation

/// Reviews display text only. It never supplies app measurements or changes model results.
enum AssistantReplyReview {
    static func clean(_ text: String) -> String {
        let text = text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: #"(?i)^\s*(?:assistant:\s*)?Here is the result from TwinTrack[.:]?\s*"#, with: "", options: .regularExpression)
        var lines: [String] = []
        for line in text.components(separatedBy: .newlines) {
            // Remove speaker labels, not the rest of the answer: a later warning or
            // a quoted user statement must not disappear with an invented role prefix.
            var line = line.replacingOccurrences(of: #"(?i)^\s*(?:\*\*)?(?:assistant|TwinTrack AI|AI assistant|user|system|developer|human)(?:\*\*)?\s*:(?:\*\*)?\s*"#, with: "", options: .regularExpression)
            line = line.replacingOccurrences(of: #"^\s*#{1,6}\s+"#, with: "", options: .regularExpression)
            line = line.replacingOccurrences(of: #"^\s*[-*]\s+"#, with: "• ", options: .regularExpression)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") { continue }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
            .replacingOccurrences(of: #"\[([^\]]+)\]\(https?://[^\s)]+\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"https?://[^\s<>]+"#, with: "[unverified link omitted]", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func formatted(_ text: String) -> AttributedString {
        var value = (try? AttributedString(markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
        // Applies to old saved replies too, without rewriting their stored content.
        // Only separately rendered registry links may open a browser.
        value.link = nil
        return value
    }

    static func containsInstructionLeak(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?im)^\s*(?:\*\*)?(?:limits|system instructions|reviewer notes|local reviewed guidance|user-stated age)\s*:|urgent action must not wait for a location question|no diagnosis or country-specific emergency number"#, text)
    }

    static func sleepGuidanceCorrection(_ text: String, messages: [AssistantMessage]) -> String? {
        let age = AssistantGuidance.statedAge(in: messages)
        if age == nil, AssistantGuidance.selected(for: messages).contains(where: { $0.topic == "sleep" }),
           AssistantRouter.matches(#"(?i)(?:^|[.!?]\s+)(?:you are|you're|you’re|at your age of) (?:\d{1,3}|sixteen)\b|^as a teenager\b"#, text) {
            return "Sleep guidance depends on age. How old are you?"
        }
        guard let age, (13...18).contains(age),
              AssistantGuidance.selected(for: messages).contains(where: { $0.id == "cdc-student-sleep" }),
              AssistantRouter.matches(#"(?i)\b(?:age|teen|years|need|needs|require|requires|recommend|recommended|aim)\b"#, text),
              AssistantRouter.matches(#"(?i)\b(?:9|nine)\s*(?:[–—-]|to)\s*(?:12|twelve)\b|\b6\s*[–—-]\s*18\b"#, text) else { return nil }
        // Replace the unsupported recommendation explicitly; never silently edit a
        // generated health number or claim that a guideline is a personal measurement.
        return "The reviewed guidance for the age you stated is: " + AssistantGuidance.teenSleepGuidance
    }

    static func isRefusal(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?i)^\s*(?:(?:i(?:'m| am) )?sorry[,.:]?\s*)?i (?:can't|cannot|won't|am unable to) (?:help|assist|provide|comply|fulfill)\b"#, clean(text).replacingOccurrences(of: "’", with: "'"))
    }

    static func containsPersonalNumbers(_ text: String) -> Bool {
        let number = #"(?:\d|\b(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred)\b)"#
        // Test factual metric claims locally, not "your sleep" anywhere plus any
        // unrelated bedtime/quantity elsewhere in the answer.
        let score = #"(?:your (?:predicted |assessment |what-if |scenario )?(?:score|prediction|delta)|(?:predicted|assessment|scenario) score)\b[^.!?\n]{0,70}"# + number
        let reading = #"(?:your (?:steps|resting heart rate|rhr|sleep|exercise|study time|screen time)\s+(?:is|are|was|were|averages?|total(?:s|ed)?|reached|has been)|you (?:slept|walked|exercised|studied))\s+(?:(?:about|around|roughly|approximately)\s+)?"# + number
        if AssistantRouter.matches("(?i)" + score, text) { return true }
        // Conditional examples and explicitly negated claims are not assertions that
        // TwinTrack measured something. Remove only their local reading clause.
        let assertions = text.replacingOccurrences(of: #"(?i)\b(?:the phrase|the words|you quoted|you wrote) [“‘"][^”’"\n]+[”’"]"#, with: "", options: .regularExpression)
        let factual = assertions.replacingOccurrences(of:
            "(?i)(?:\\bif |\\bwhether |\\bimagine |\\bi (?:can't|cannot|do not|don't) (?:say|know|claim) (?:that )?)" + reading,
            with: "", options: .regularExpression)
        return AssistantRouter.matches("(?i)" + reading, factual)
    }

    static func labelReportedSleep(_ text: String, messages: [AssistantMessage]) -> String {
        let amount = #"(\d+(?:\.\d+)?|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)"#
        let reports = messages.filter { $0.role == .user }.suffix(6).flatMap {
            AssistantRouter.captures("(?i)(?:^|[.!?]\\s+)(?:i slept|i got) " + amount + " hours?\\b", $0.text).compactMap(\.first)
        }
        func value(_ word: String) -> Double? {
            if let number = Double(word) { return number }
            let formatter = NumberFormatter(); formatter.locale = Locale(identifier: "en_US"); formatter.numberStyle = .spellOut
            return formatter.number(from: word.lowercased())?.doubleValue
        }
        var result = text
        for match in AssistantRouter.captures("(?i)((?:you slept|your sleep was) " + amount + " hours?)", text) where match.count == 2 {
            guard let duration = value(match[1]), reports.contains(where: { value($0) == duration }) else { continue }
            // Sensor attribution is reviewed separately and cannot be legitimized by a report.
            result = result.replacingOccurrences(of: match[0], with: "you reported sleeping \(match[1]) hours")
        }
        return result
    }

    static func containsInventedGrounding(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?i)\b(?:based on|looking at|according to|from) your (?:recent |current |recorded |health )?(?:activity|readings|healthkit|data|records|sleep patterns)|\byour (?:watch|healthkit|activity|health data|records) (?:shows?|suggests?|indicates?|recorded|measured)\b"#, text)
    }

    static func containsMedicationAdvice(_ text: String) -> Bool {
        let medicine = #"(?:medication|medicine|painkillers?|pain relie(?:f|vers?)|ibuprofen|paracetamol|acetaminophen|aspirin|antacids?|antibiotics?|laxatives?|sleeping pills?)"#
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?\n")).contains { sentence in
            // Advice to consult a professional or avoid self-medication is retained.
            guard !AssistantRouter.matches(#"(?i)^\s*(?:you (?:should|must) not|don't|do not|avoid|never)\s+(?:take|taking|try|trying|use|using|start|starting|change|changing)\b"#, sentence) else { return false }
            return AssistantRouter.matches(#"(?i)\b(?:take|try|use|start|consider|recommend)\b.{0,55}\b"# + medicine, sentence)
                || AssistantRouter.matches("(?i)\\b" + medicine + #"\b.{0,40}\b(?:can|may|will) help\b"#, sentence)
        }
    }

    static func containsImmediateEmergencyDirective(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?i)\bcall\s+(?:998|an ambulance|emergency services)\b|\bcontact (?:local )?emergency services now\b"#, text)
    }

    static func reviewed(_ text: String, request: String) -> String {
        let requestIsUrgent = AssistantGuidance.isUrgent(request)
        // A generated warning can mention red flags without proving that the user
        // reported one. Never turn that warning into an immediate ambulance order.
        if !requestIsUrgent, AssistantGuidance.isSymptomRequest(request), containsImmediateEmergencyDirective(text) {
            return AssistantResponsePolicy.symptomGuidance(for: request)
        }
        // Replace unsafe advice, rather than adding a disclaimer to it. Keep urgent
        // escalation early only when the user's own message establishes a red flag.
        if containsMedicationAdvice(text) {
            return requestIsUrgent ? AssistantResponsePolicy.urgent : AssistantResponsePolicy.symptomGuidance(for: request)
        }
        if containsInventedGrounding(text) {
            if requestIsUrgent { return AssistantResponsePolicy.urgent }
            // Discard the unsupported inference with its recommendation; do not
            // make the same personal inference appear valid by removing attribution.
            return "I haven't accessed your activity or health records for this reply, so I can't base advice on them. I can discuss general habits, or you can ask TwinTrack to show your current data."
        }
        return text
    }
}
