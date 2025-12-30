import Foundation

/// Processor for simple text cleanup - removes filler words and repeated words
class SimpleCleanupProcessor {
    static let shared = SimpleCleanupProcessor()

    // Filler words to remove (case insensitive)
    private let fillerWords: Set<String> = [
        "um", "umm", "uh", "uhh", "uh-huh",
        "hmm", "hm", "hmmmm",
        "ah", "ahh", "ahhh",
        "er", "err",
        "like",  // When used as filler
        "you know",
        "i mean",
        "basically",
        "actually",
        "literally",
        "right",  // When used as filler
        "so",     // When at start as filler
        "well",   // When at start as filler
        "anyway",
        "anyways"
    ]

    // Regex patterns for filler detection
    private lazy var fillerPatterns: [(NSRegularExpression, String)] = {
        var patterns: [(NSRegularExpression, String)] = []

        // Basic filler words with word boundaries
        let basicFillers = ["umm?", "uhh?", "hmm+", "ahh?", "err?"]
        for filler in basicFillers {
            if let regex = try? NSRegularExpression(pattern: "\\b\(filler)\\b", options: .caseInsensitive) {
                patterns.append((regex, ""))
            }
        }

        // Filler phrases
        let fillerPhrases = ["you know", "i mean", "you see"]
        for phrase in fillerPhrases {
            if let regex = try? NSRegularExpression(pattern: "\\b\(phrase)\\b,?", options: .caseInsensitive) {
                patterns.append((regex, ""))
            }
        }

        // "Like" as filler (not "I like" or "looks like")
        if let regex = try? NSRegularExpression(pattern: "(?<!i )(?<!looks )\\blike\\b(?! that| this| it| a| the| to)", options: .caseInsensitive) {
            patterns.append((regex, ""))
        }

        return patterns
    }()

    // Repeated word pattern: "the the" -> "the"
    private lazy var repeatedWordRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\b(\\w+)\\s+\\1\\b", options: .caseInsensitive)
    }()

    // Multiple spaces to single space
    private lazy var multipleSpacesRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\s{2,}", options: [])
    }()

    // Multiple punctuation
    private lazy var multiplePunctuationRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "([.!?,;]){2,}", options: [])
    }()

    private init() {}

    // MARK: - Processing

    func process(_ text: String) -> String {
        var result = text

        // Remove filler words
        result = removeFillerWords(result)

        // Remove repeated words
        result = removeRepeatedWords(result)

        // Clean up punctuation
        result = cleanupPunctuation(result)

        // Clean up whitespace
        result = cleanupWhitespace(result)

        // Capitalize first letter
        result = capitalizeFirst(result)

        return result
    }

    // MARK: - Individual Cleanup Steps

    private func removeFillerWords(_ text: String) -> String {
        var result = text

        for (regex, replacement) in fillerPatterns {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement
            )
        }

        return result
    }

    private func removeRepeatedWords(_ text: String) -> String {
        guard let regex = repeatedWordRegex else { return text }

        // Apply multiple times in case of triple repetition
        var result = text
        var previousResult = ""

        while result != previousResult {
            previousResult = result
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }

        return result
    }

    private func cleanupPunctuation(_ text: String) -> String {
        var result = text

        // Remove multiple punctuation marks
        if let regex = multiplePunctuationRegex {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }

        // Remove space before punctuation
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " .", with: ".")
        result = result.replacingOccurrences(of: " !", with: "!")
        result = result.replacingOccurrences(of: " ?", with: "?")

        return result
    }

    private func cleanupWhitespace(_ text: String) -> String {
        var result = text

        // Multiple spaces to single space
        if let regex = multipleSpacesRegex {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: " "
            )
        }

        // Trim leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    private func capitalizeFirst(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
