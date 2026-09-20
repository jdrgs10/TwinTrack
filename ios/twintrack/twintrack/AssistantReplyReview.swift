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

    static func containsProviderIdentity(_ text: String) -> Bool {
        let normalized = clean(text).replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: #"[“\"][^”\"\n]{0,240}[”\"]"#, with: "", options: .regularExpression)
        return AssistantRouter.matches(#"(?i)\b(?:as |i(?:'m| am) )(?:a |an )?(?:chatbot|ai|ai assistant|assistant|language model)[^.!?\n]{0,50}\b(?:created|made|developed|built|provided) by Apple\b"#, normalized)
            || AssistantRouter.matches(#"(?i)\bas Apple(?:'s)? (?:chatbot|ai|ai assistant|assistant|language model)\b"#, normalized)
    }

    static func removingProviderIntroduction(_ text: String) -> String {
        guard containsProviderIdentity(text) else { return text }
        // Remove only the false identity clause. Its presence is not a safety verdict.
        return text.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of:
            #"(?i)\b(?:as |i(?:'m| am) )(?:a |an )?(?:chatbot|ai assistant|assistant|language model|ai)[^.!?\n]{0,50}\b(?:created|made|developed|built|provided) by Apple\s*[,.:]?\s*"#,
            with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)\bas Apple(?:'s)? (?:chatbot|ai assistant|assistant|language model|ai)\s*[,.:]?\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sleepGuidanceCorrection(_ text: String, messages: [AssistantMessage]) -> String? {
        guard !isRefusal(text) else { return nil }
        let age = AssistantGuidance.statedAge(in: messages)
        if inventsSleepAge(text, messages: messages) {
            return "Sleep guidance depends on age. How old are you?"
        }
        if hasUnfoundedSleepDuration(text, messages: messages) {
            return "Sleep needs vary by age; there isn't one recommended duration for every student."
        }
        guard let age, (13...18).contains(age),
              AssistantGuidance.selected(for: messages).contains(where: { $0.id == "cdc-student-sleep" }),
              AssistantRouter.matches(#"(?i)\b(?:age|teen|years|need|needs|require|requires|recommend|recommended|aim)\b"#, text),
              AssistantRouter.matches(#"(?i)\b(?:9|nine)\s*(?:[–—-]|to)\s*(?:12|twelve)\b|\b6\s*[–—-]\s*18\b"#, text) else { return nil }
        // Replace the unsupported recommendation explicitly; never silently edit a
        // generated health number or claim that a guideline is a personal measurement.
        return "The reviewed guidance for the age you stated is: " + AssistantGuidance.teenSleepGuidance
    }

    static func inventsSleepAge(_ text: String, messages: [AssistantMessage]) -> Bool {
        AssistantGuidance.statedAge(in: messages) == nil
            && AssistantGuidance.selected(for: messages).contains(where: { $0.topic == "sleep" })
            && AssistantRouter.matches(#"(?i)(?:^|[.!?]\s+)(?:you are|you're|you’re|at your age of) (?:\d{1,3}|sixteen)\b|^as a teenager\b"#, text)
    }

    static func hasUnfoundedSleepDuration(_ text: String, messages: [AssistantMessage]) -> Bool {
        guard AssistantGuidance.statedAge(in: messages) == nil,
              AssistantGuidance.selected(for: messages).contains(where: { $0.topic == "sleep" }) else { return false }
        let range = #"(?:[0-9]+|seven|eight|nine|ten)\s*(?:(?:[–—-]|to)\s*(?:[0-9]+|seven|eight|nine|ten))?\s*hours?"#
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?\n")).contains { clause in
            if AssistantRouter.matches(#"(?i)\byou (?:should|need|must)\b[^.!?\n]{0,50}"# + range, clause) { return true }
            // Attributed age-group guidance is distinct from a personal prescription.
            guard !AssistantRouter.matches(#"(?i)\b(?:adult|adults|ages?|teen|teens|teenagers|children|child)\b"#, clause) else { return false }
            return AssistantRouter.matches(#"(?i)\b(?:aim for|try to get|recommend(?:ed)?)\b[^.!?\n]{0,50}"# + range, clause)
                || AssistantRouter.matches(#"(?i)^\s*get\s+"# + range, clause)
        }
    }

    static func isRefusal(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?i)^\s*(?:(?:i(?:'m| am) )?sorry[,.:]?\s*(?:but\s+)?)?i (?:can't|cannot|won't|am unable to) (?:help|assist|provide|comply|fulfill|answer|respond)\b"#, clean(text).replacingOccurrences(of: "’", with: "'"))
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

    static func containsMentalHealthCrisisEscalation(_ text: String) -> Bool {
        if AssistantRouter.matches(#"(?i)\b(?:suicid(?:e|al)|self[ -]?harm|harm(?:ing)? yourself|hurt(?:ing)? yourself|end(?:ing)? your life|crisis (?:line|hotline|support|resources?)|mental[ -]?health (?:crisis|emergency))\b"#, text) {
            return true
        }
        return AssistantRouter.matches(#"(?i)\b(?:immediate danger|safe right now|not alone|someone you trust|trusted (?:adult|person))\b"#, text)
            && AssistantRouter.matches(#"(?i)\b(?:crisis|emergency|urgent|support|help)\b"#, text)
    }

    static func reviewed(_ text: String, request: String, messages: [AssistantMessage] = []) -> String {
        let requestIsUrgent = AssistantGuidance.isUrgent(request)
        // The on-device model can occasionally over-read a standalone casual decline
        // as distress. Suppress only that generated escalation, and never when the
        // user's recent messages contain an explicit self-harm or suicide indicator.
        if AssistantContext.isCasualAcknowledgement(request),
           !AssistantContext.hasCredibleMentalHealthCrisis(in: messages),
           containsMentalHealthCrisisEscalation(text) {
            return AssistantResponsePolicy.casualAcknowledgement
        }
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

/// Conversation quality checks are separate from medical/safety review. They never
/// truncate an answer or edit a numerical result, and do not persist rejected text.
enum AssistantConversationReview {
    static let fallback = "I couldn’t explain that clearly. Could you point to the part you want clarified?"

    static func issue(in text: String, messages: [AssistantMessage]) -> String? {
        guard let request = messages.last?.text else { return nil }
        let earlier = messages.dropLast()
        let previous = earlier.last?.role == .assistant ? earlier.last : nil
        guard !AssistantContext.requiresSafetyContext(for: messages),
              !AssistantContext.hasCredibleMentalHealthCrisis(in: messages),
              !AssistantGuidance.isSymptomRequest(request),
              !AssistantGuidance.isUrgent(request),
              !AssistantReplyReview.containsMentalHealthCrisisEscalation(text),
              !AssistantReplyReview.containsImmediateEmergencyDirective(text) else { return nil }
        // Review relevance only for routine conversation; clinical warnings and
        // genuine refusals must not be shortened or displaced by a quality repair.
        if AssistantReplyReview.isRefusal(text) {
            guard let previous, !AssistantContext.isRefusal(previous),
                  request.split(whereSeparator: { $0.isWhitespace }).count <= 5 else { return nil }
            return "Resolve the latest brief turn from the last exchange, with the same safeguards. If it requests prohibited help, keep the refusal; otherwise answer the contextual question."
        }
        // The established app-owned invented-age correction has priority over
        // generative quality repair, so a retry cannot obscure that safeguard.
        if AssistantReplyReview.inventsSleepAge(text, messages: messages) { return nil }
        if AssistantReplyReview.hasUnfoundedSleepDuration(text, messages: messages) {
            return "The user's age is unknown. Do not apply a fixed sleep-duration recommendation to them. Answer the actual question; if duration is relevant, explain that recommendations vary by age."
        }
        let topic = AssistantGuidance.topicContext(for: messages)
        let chronicRisks = #"(?i)\b(?:obesity|diabetes|heart disease|immune system)\b"#
        if !requestsDetail(request), AssistantRouter.matches(#"(?i)\bsleep\b"#, topic),
           !AssistantRouter.matches(chronicRisks, topic), AssistantRouter.matches(chronicRisks, text) {
            return "Answer the sleep question actually asked. Explain the relevant recovery/alertness/concentration mechanism briefly; omit unrelated chronic-disease or immune-system advice. Preserve any necessary safety guidance."
        }
        let normalized = normalize(text)
        if let previous, normalized == normalize(previous.text), !normalized.isEmpty {
            return "Give a new answer to the latest turn using the last exchange. Do not repeat the previous answer. Keep all safeguards."
        }
        let assertions = text.replacingOccurrences(of: #"[“\"][^”\"\n]*[”\"]|‘[^’\n]*’"#, with: "", options: .regularExpression)
        if AssistantRouter.matches(#"(?i)\bI(?: am|'m)? (?:planning to|going for a|went for a|enjoyed my|walked|slept|ate|visited|feel the breeze)\b|\bmy (?:walk|workout|breakfast|weekend plans)\b"#, assertions.replacingOccurrences(of: "’", with: "'")) {
            return "Answer about the user's topic. Do not claim physical experiences or personal plans. Keep all safeguards."
        }
        if hasUnsupportedCurrentConditions(text) {
            return "No current weather, air-quality or environmental measurements are available. Distinguish the user's subjective impression from verified conditions. Explain possibilities conditionally; do not certify today's conditions."
        }
        if repeatsExplanation(text, previous: previous?.text) {
            return "Advance the explanation: identify what the latest turn seeks and add the missing mechanism or connection. Do not paraphrase the earlier answer or append unrelated tips."
        }
        return nil
    }

    static func requestsDetail(_ text: String) -> Bool {
        AssistantRouter.matches(#"(?i)\b(?:detail(?:ed)?|thorough(?:ly)?|comprehensive|step.by.step|in depth|long explanation)\b"#, text)
    }

    static func hasUnsupportedCurrentConditions(_ text: String) -> Bool {
        // A narrow unsupported-claim category, not a weather fact checker. General
        // science, conditional possibilities and attributed observations remain valid.
        let clauses = text.components(separatedBy: CharacterSet(charactersIn: ".!?;\n"))
            .flatMap { $0.components(separatedBy: " but ") }
        return clauses.contains { clause in
            guard !AssistantRouter.matches(#"(?i)\b(?:if|may|might|could|can|perhaps|possibly|looks?|seems?|appears?|you (?:said|say|described)|cannot|can't|don't know|not necessarily)\b"#, clause) else { return false }
            return AssistantRouter.matches(#"(?i)\b(?:the|your|today's|local) (?:air|sky|weather|air quality|pollution|humidity|temperature)\s+(?:is|are|has|contains)\b"#, clause)
                || AssistantRouter.matches(#"(?i)\b(?:air|sky|weather|pollution|humidity|temperature)\b.{0,35}\b(?:today|right now|outside your|in your area)\b"#, clause)
        }
    }

    static func repeatsExplanation(_ text: String, previous: String?) -> Bool {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { normalize($0) }.filter { $0.split(separator: " ").count >= 5 }
        if Set(sentences).count < sentences.count { return true }
        guard let previous else { return false }
        let prior = contentWords(previous), current = contentWords(text)
        guard prior.count >= 6, current.count >= 6 else { return false }
        let shared = current.intersection(prior).count
        return Double(shared) / Double(current.count) >= 0.75 && current.subtracting(prior).count <= 2
    }

    private static func contentWords(_ text: String) -> Set<String> {
        let stopWords: Set<String> = ["the", "a", "an", "and", "or", "to", "of", "in", "for", "is", "are", "it", "that", "this", "you", "your", "with", "by", "so", "can", "helps", "help", "because", "during", "while"]
        return Set(text.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count > 2 && !stopWords.contains($0) })
    }

    private static func normalize(_ text: String) -> String {
        AssistantReplyReview.clean(text).lowercased()
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
}
