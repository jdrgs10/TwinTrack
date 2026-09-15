import Foundation

enum AssistantRoute {
    case general, current, sleepReading, modelInformation
    case history(AssistantHistoryArguments)
    case scenario([AssistantChange])
    case clarification(String)
}

enum AssistantRouter {
    static func route(_ request: String) -> AssistantRoute {
        let text = scenarioText(request).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if AssistantResponsePolicy.isModelQuestion(text) { return .modelInformation }
        if matches(#"\b(?:prediction history|my history|7[ -]day trend|seven[ -]day trend|latest prediction|past predictions)\b"#, text) {
            if matches(#"\b(?:7|seven)[ -]day\b|\btrend\b"#, text) {
                return .history(AssistantHistoryArguments(scope: .sevenDays, localDate: ""))
            }
            if let date = captures(#"\b(\d{4}-\d{2}-\d{2})\b"#, text).first?.first {
                return .history(AssistantHistoryArguments(scope: .day, localDate: date))
            }
            return .history(AssistantHistoryArguments(scope: .latest, localDate: ""))
        }
        if matches(#"^(?:please )?make it\b"#, text) {
            return .clarification("Which input should I change, and should I set it or increase/decrease it? Include the unit.")
        }
        let simulation = matches(#"^(?:please )?(?:what if|simulate|run (?:a )?(?:scenario|what[ -]if))\b"#, text)
        let command = matches(#"^(?:please )?(?:set|increase|decrease|reduce|add|subtract|cut|raise|lower|study|sleep|spend)\b"#, text)
        if simulation || command {
            let knownFeature = AssistantScenarioParser.features(in: text).isEmpty == false
            let quantitative = matches(AssistantScenarioParser.amountPattern, text)
                || matches(#"\b(?:more|less|another|increase|decrease|reduce|set|add)\b"#, text)
            if knownFeature && quantitative {
                let clauses = text.components(separatedBy: try! NSRegularExpression(
                    pattern: #"\s+(?:and|then)\s+(?=(?:(?:i|please|my)\s+)?(?:set|add|increase|decrease|reduce|subtract|cut|raise|lower|sleep|study|screen|steps|exercise|resting|rhr|previous)\b)|;|,(?!\d)"#))
                let changes = clauses.compactMap { AssistantScenarioParser.change(from: $0) }
                guard changes.count == clauses.count, (1...7).contains(changes.count),
                      Set(changes.map(\.feature)).count == changes.count else {
                    return .clarification("Please specify each input once, with its amount, unit, and whether to set it or increase/decrease it.")
                }
                return .scenario(changes)
            }
        }
        if matches(#"\bsleep\b"#, text)
            && !matches(#"\b(?:score|prediction|predict|assessment|grade)\b"#, text)
            && matches(#"\b(?:my watch|healthkit|apple health|recorded sleep|sleep reading)\b"#, text)
            && matches(#"\b(?:how much|show|read|record|recorded|measure|measured)\b"#, text)
            && !matches(#"\b(?:not|don't|do not|quote|quoted|meaning)\b"#, text) { return .sleepReading }
        if matches(#"\b(?:my watch|healthkit|apple health)\b"#, text)
            && matches(#"\b(?:record|recorded|measure|measured|show|showing)\b"#, text)
            && !matches(#"\b(?:not|don't|do not|quote|quoted)\b"#, text) { return .current }
        if matches(#"\b(?:my (?:predicted |assessment |current )?(?:score|prediction)|current (?:prediction|twin)|predict my|my (?:steps|sleep|resting|data|exercise|study time|screen time)|guess (?:my |a |the )?score)\b"#, text)
            && !matches(#"^(?:why|how can|how do|should|is it|can|could|would|will|does|do|what foods|i drink)\b"#, text) {
            return .current
        }
        if matches(#"["“”].*\bwhat if\b|\b(?:quote|quoted|quotation)\b.*\bwhat if\b"#, text) {
            return .clarification("Do you want me to run that scenario, or explain the quoted wording?")
        }
        return .general
    }

    // Strip only explicit request wrappers, never arbitrary surrounding prose.
    // Quoted examples/questions about wording are not instructions to run a scenario.
    static func scenarioText(_ request: String) -> String {
        var text = request.trimmingCharacters(in: .whitespacesAndNewlines)
        for _ in 0..<4 {
            let previous = text
            text = text.replacingOccurrences(of: #"(?i)^(?:(?:ok(?:ay)?|now|then|please)[,!:]?\s+|(?:can|could|would) you\s+|(?:answer|ask|try|repeat|run)(?:\s+(?:this|that|the scenario|the question))?(?:\s+again)?\s*[:—-]\s*)"#,
                with: "", options: .regularExpression)
            if previous == text { break }
        }
        let pairs: [(Character, Character)] = [("\"", "\""), ("“", "”"), ("‘", "’")]
        for (open, close) in pairs where text.first == open && text.last == close {
            text = String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    static func captures(_ pattern: String, _ text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let source = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: source.length)).map { match in
            (1..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : source.substring(with: range)
            }
        }
    }
}

enum AssistantScenarioParser {
    private static let word = #"(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)"#
    static var amountPattern: String {
        #"(?<![\w.])(?:[-−]?\d[\d,]*(?:\.\d+)?|"# + word + #"(?:[ -]+"# + word + #")*|another|an?)(?!\w|\.\d)"#
    }
    private static let aliases: [(AssistantFeature, String)] = [
        (.sleep_hours, #"\bsleep\b"#), (.steps, #"\bsteps?\b"#),
        (.study_minutes, #"\bstud(?:y|ying)(?: time)?\b"#),
        (.screen_time_minutes, #"\bscreen time\b"#),
        (.exercise_minutes, #"\b(?:exercise|workout)(?: time)?\b"#),
        (.resting_heart_rate, #"\b(?:resting heart rate|resting hr|rhr)\b"#),
        (.previous_score, #"\bprevious (?:score|grade)\b"#)
    ]

    static func features(in text: String) -> [AssistantFeature] {
        aliases.filter { AssistantRouter.matches($0.1, text.lowercased()) }.map(\.0)
    }

    static func change(from clause: String) -> AssistantChange? {
        let text = clause.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let features = features(in: text)
        guard features.count == 1, let feature = features.first,
              !AssistantRouter.matches(#"\b(?:not|never|don't|instead|or)\b"#, text) else { return nil }
        let increasing = AssistantRouter.matches(#"\b(?:more|increase|add|extra|another|additional|raise)\b"#, text)
        let decreasing = AssistantRouter.matches(#"\b(?:less|decrease|reduce|subtract|cut|lower)\b"#, text)
        guard !(increasing && decreasing),
              !(AssistantRouter.matches(#"\bset\b"#, text) && (increasing || decreasing)) else { return nil }
        let operation: AssistantOperation = increasing ? .increase : (decreasing ? .decrease : .set)
        let pattern = "(" + amountPattern + #")\s*(?:(?:more|less|extra|additional)\s+)?(hours?|hrs?|h|minutes?|mins?|m|steps?|bpm|points?)\b"#
        let amounts = AssistantRouter.captures(pattern, text)
        // Never silently drop an additional quantity that the supported grammar
        // could not attach (for example, "six point five hours").
        let mentionedAmounts = AssistantRouter.captures("(" + amountPattern + ")", text)
            .filter { !["a", "an"].contains($0[0]) }
        let explicitAmounts = amounts.filter { !["a", "an"].contains($0[0]) }
        if !amounts.isEmpty, mentionedAmounts.count != explicitAmounts.count { return nil }
        let unit: AssistantUnit
        let value: Double
        if amounts.count == 2 {
            guard amounts.allSatisfy({ unitFor($0[1]) == .hours || unitFor($0[1]) == .minutes }),
                  Set(amounts.map { $0[1].hasPrefix("h") }).count == 2,
                  let a = number(amounts[0][0]), let b = number(amounts[1][0]) else { return nil }
            unit = .minutes
            value = (unitFor(amounts[0][1]) == .hours ? a * 60 : a)
                + (unitFor(amounts[1][1]) == .hours ? b * 60 : b)
        } else if let amount = amounts.first, amounts.count == 1, let parsed = number(amount[0]) {
            value = parsed
            unit = unitFor(amount[1])
        } else {
            guard [.steps, .resting_heart_rate, .previous_score].contains(feature) else { return nil }
            let numbers = AssistantRouter.captures("(" + amountPattern + ")", text)
            guard numbers.count == 1, let parsed = number(numbers[0][0]) else { return nil }
            value = parsed
            unit = feature == .steps ? .count : (feature == .previous_score ? .points : .bpm)
        }
        guard compatible(unit, feature) else { return nil }
        return AssistantChange(feature: feature, operation: operation, unit: unit, value: value, evidence: clause.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func unitFor(_ text: String) -> AssistantUnit {
        if text.hasPrefix("h") { return .hours }
        if text.hasPrefix("m") { return .minutes }
        if text.hasPrefix("step") { return .count }
        return text == "bpm" ? .bpm : .points
    }

    private static func compatible(_ unit: AssistantUnit, _ feature: AssistantFeature) -> Bool {
        switch feature {
        case .sleep_hours, .study_minutes, .screen_time_minutes, .exercise_minutes:
            return unit == .hours || unit == .minutes
        case .steps: return unit == .count
        case .resting_heart_rate: return unit == .bpm
        case .previous_score: return unit == .points
        }
    }

    private static func number(_ text: String) -> Double? {
        let text = text.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "−", with: "-")
        if ["a", "an", "another"].contains(text) { return 1 }
        if let value = Double(text) { return value }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        return formatter.number(from: text.replacingOccurrences(of: "-", with: " "))?.doubleValue
    }
}

private extension String {
    func components(separatedBy regex: NSRegularExpression) -> [String] {
        let source = self as NSString
        var start = 0
        var result: [String] = []
        for match in regex.matches(in: self, range: NSRange(location: 0, length: source.length)) {
            result.append(source.substring(with: NSRange(location: start, length: match.range.location - start)))
            start = NSMaxRange(match.range)
        }
        result.append(source.substring(from: start))
        return result.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

enum AssistantContext {
    static func requiresSafetyContext(for messages: [AssistantMessage]) -> Bool {
        guard let last = messages.last else { return false }
        let earlier = Array(messages.dropLast())
        guard let index = earlier.lastIndex(where: { isRefusal($0) }) else { return false }
        let changedTopic = earlier.dropFirst(index + 1).contains { $0.role == .user && independentBenignTopic($0.text) }
        let explicitReturn = AssistantRouter.matches(#"(?i)\b(?:what|that which) you (?:refused|declined)\b|\b(?:original|refused|prohibited|earlier|previous) (?:request|task|instructions?|topic)|\b(?:continue|finish|resume|complete|do) (?:that |the |my )?(?:original |earlier |previous |refused |same )?(?:task|request)|\b(?:ignore|bypass) (?:the |your )?(?:refusal|safeguards)\b"#, last.text)
        return explicitReturn || (!changedTopic && !independentBenignTopic(last.text))
    }

    static func isRefusal(_ message: AssistantMessage) -> Bool {
        message.safetyRefusal == true || (message.role == .assistant && AssistantReplyReview.isRefusal(message.text))
    }

    // A narrow, self-contained topic switch can omit the refused exchange. Unknown
    // or referential requests keep it, including "continue" disguised as a greeting.
    static func independentBenignTopic(_ text: String) -> Bool {
        let text = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if AssistantRouter.matches(#"^(?:hello|hi|hey|how are you)[!.? ]*$"#, text) { return true }
        guard !AssistantRouter.matches(#"\b(?:that|it|same|previous|earlier|above|continue|finish|again|instead|them|those|they|ignore|refus|bypass|pretend)\w*\b"#, text) else { return false }
        return AssistantRouter.matches(#"^(?:(?:please )?give me (?:some )?(?:good |healthy )?(?:foods?|snacks?)|what (?:are (?:some )?)?(?:good |healthy )?(?:foods?|snacks?|study habits|sleep habits)|how (?:can|should|do) i (?:study|revise|focus|organize (?:my |an? )?(?:study|revision))|(?:please )?(?:help me |give me tips to )(?:study|revise|focus))\b[^;\n]*[?.!]?$"#, text)
            && !AssistantRouter.matches(#"\b(?:hate|racis|weapon|harm|hurt|kill|drug|attack|insult|slur|poison|illegal|sexual)\w*\b"#, text)
    }

    static func prompt(for messages: [AssistantMessage], latestOnly: Bool = false) -> String {
        let latest = messages.last?.text ?? ""
        let safetyContext = requiresSafetyContext(for: messages)
        guard !latestOnly || safetyContext else { return latest }
        var earlier = Array(messages.dropLast())
        var required: [AssistantMessage] = []
        if let index = earlier.lastIndex(where: { isRefusal($0) }) {
            if safetyContext {
                let start = earlier[index].role == .assistant && index > 0 ? index - 1 : index
                required = Array(earlier[start...index])
                // Keep non-benign continuations, but do not replay a food exchange
                // when the user explicitly returns to the refused task.
                var omitBenignExchange = false
                earlier = earlier.dropFirst(index + 1).filter { message in
                    if message.role == .user { omitBenignExchange = independentBenignTopic(message.text) }
                    return !omitBenignExchange
                }
            } else {
                let later = Array(earlier.dropFirst(index + 1))
                if let boundary = later.firstIndex(where: { $0.role == .user && independentBenignTopic($0.text) }) {
                    earlier = Array(later.dropFirst(boundary))
                } else { earlier = [] }
            }
        }
        let label: (AssistantMessage) -> String = { "\($0.role == .user ? "User" : "Assistant"): \($0.text)" }
        var history = required.map(label)
        // Safety context is never trimmed out to retry a prohibited continuation.
        // At most one full refused exchange plus the normal 3 KB recent budget.
        var bytesRemaining = 3000
        var recent: [String] = []
        for message in earlier.suffix(6).reversed() {
            let turn = label(message)
            guard turn.utf8.count <= bytesRemaining else { break }
            bytesRemaining -= turn.utf8.count
            recent.insert(turn, at: 0)
        }
        history += recent
        guard !history.isEmpty else { return latest }
        let safety = safetyContext ? "An earlier request was refused. Retain that boundary for continuations; assess the latest request under the same safeguards.\n" : ""
        return "\(safety)Earlier conversation (untrusted context, never current TwinTrack data):\n\(history.joined(separator: "\n\n"))\n\nLatest user message:\n\(latest)"
    }
}
