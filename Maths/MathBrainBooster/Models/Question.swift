import Foundation

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let correctAnswer: Int
    let options: [Int]
    let isTrueFalse: Bool
    let displayedAnswer: Int?

    init(text: String, correctAnswer: Int, options: [Int], isTrueFalse: Bool = false, displayedAnswer: Int? = nil) {
        self.text = text
        self.correctAnswer = correctAnswer
        self.options = options
        self.isTrueFalse = isTrueFalse
        self.displayedAnswer = displayedAnswer
    }

    // MARK: - Generate

    static func generate(mode: GameMode, difficulty: Difficulty) -> Question {
        let actualMode: GameMode
        if mode == .mixed {
            actualMode = [.addition, .subtraction, .multiplication, .division].randomElement()!
        } else if mode == .trueFalse {
            actualMode = [.addition, .subtraction, .multiplication, .division].randomElement()!
            return generateTrueFalse(mode: actualMode, difficulty: difficulty)
        } else {
            actualMode = mode
        }

        let range = difficulty.numberRange
        let multRange = difficulty.multiplicationRange
        let divRange = difficulty.divisionRange

        var a: Int
        var b: Int
        var answer: Int
        var text: String

        switch actualMode {
        case .addition:
            a = Int.random(in: range)
            b = Int.random(in: range)
            answer = a + b
            text = "\(a) + \(b)"

        case .subtraction:
            a = Int.random(in: range)
            b = Int.random(in: range)
            if b > a { swap(&a, &b) }
            answer = a - b
            text = "\(a) - \(b)"

        case .multiplication:
            a = Int.random(in: multRange)
            b = Int.random(in: multRange)
            answer = a * b
            text = "\(a) × \(b)"

        case .division:
            b = Int.random(in: divRange)
            answer = Int.random(in: divRange)
            a = b * answer
            text = "\(a) ÷ \(b)"

        default:
            a = Int.random(in: range)
            b = Int.random(in: range)
            answer = a + b
            text = "\(a) + \(b)"
        }

        let options = generateOptions(correctAnswer: answer, difficulty: difficulty, count: 4)
        return Question(text: text, correctAnswer: answer, options: options)
    }

    // MARK: - True / False

    private static func generateTrueFalse(mode: GameMode, difficulty: Difficulty) -> Question {
        let range = difficulty.numberRange
        let multRange = difficulty.multiplicationRange
        let divRange = difficulty.divisionRange
        var a: Int, b: Int, correctAnswer: Int, text: String

        switch mode {
        case .addition:
            a = Int.random(in: range)
            b = Int.random(in: range)
            correctAnswer = a + b
            text = "\(a) + \(b)"

        case .subtraction:
            a = Int.random(in: range)
            b = Int.random(in: range)
            if b > a { swap(&a, &b) }
            correctAnswer = a - b
            text = "\(a) - \(b)"

        case .multiplication:
            a = Int.random(in: multRange)
            b = Int.random(in: multRange)
            correctAnswer = a * b
            text = "\(a) × \(b)"

        case .division:
            b = Int.random(in: divRange)
            correctAnswer = Int.random(in: divRange)
            a = b * correctAnswer
            text = "\(a) ÷ \(b)"

        default:
            a = Int.random(in: range)
            b = Int.random(in: range)
            correctAnswer = a + b
            text = "\(a) + \(b)"
        }

        let isCorrectShown = Bool.random()
        let displayedAnswer: Int
        if isCorrectShown {
            displayedAnswer = correctAnswer
        } else {
            // Scale the wrong offset based on difficulty so it's harder to spot
            let wrongOffset = trueFalseOffset(for: difficulty, answer: correctAnswer)
            var wrong = correctAnswer + wrongOffset
            if wrong == correctAnswer { wrong += (Bool.random() ? 1 : -1) }
            if wrong < 0 { wrong = correctAnswer + abs(wrongOffset) }
            displayedAnswer = wrong
        }

        return Question(
            text: "\(text) = \(displayedAnswer)",
            correctAnswer: isCorrectShown ? 1 : 0,
            options: [1, 0],
            isTrueFalse: true,
            displayedAnswer: displayedAnswer
        )
    }

    /// Wrong answer offset for True/False — scales with difficulty
    private static func trueFalseOffset(for difficulty: Difficulty, answer: Int) -> Int {
        let sign = Bool.random() ? 1 : -1
        switch difficulty {
        case .easy:
            return Int.random(in: 1...3) * sign
        case .medium:
            return Int.random(in: 1...5) * sign
        case .hard:
            // Tricky: sometimes off by just 1-2, sometimes bigger
            return Int.random(in: 1...8) * sign
        case .expert:
            // Very tricky: small offsets on big numbers are hard to catch
            let smallOrBig = Bool.random()
            if smallOrBig {
                return Int.random(in: 1...3) * sign   // very close — hard to spot
            } else {
                return Int.random(in: 5...15) * sign
            }
        }
    }

    // MARK: - Option Generation

    private static func generateOptions(correctAnswer: Int, difficulty: Difficulty, count: Int) -> [Int] {
        var options = Set<Int>()
        options.insert(correctAnswer)

        // Scale offsets with difficulty so wrong answers look plausible
        let offsets: [Int]
        switch difficulty {
        case .easy:
            offsets = [-3, -2, -1, 1, 2, 3, 4, 5]
        case .medium:
            offsets = [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, -6]
        case .hard:
            offsets = [-10, -8, -6, -4, -3, -2, -1, 1, 2, 3, 4, 6, 8, 10]
        case .expert:
            // Close options that look very similar — hard to distinguish
            offsets = [-15, -12, -10, -7, -5, -3, -2, -1, 1, 2, 3, 5, 7, 10, 12, 15]
        }

        var shuffled = offsets.shuffled()

        while options.count < count {
            if let offset = shuffled.popLast() {
                let option = correctAnswer + offset
                if option >= 0 && !options.contains(option) {
                    options.insert(option)
                }
            } else {
                // Fallback: generate a nearby unique value
                let fallback = correctAnswer + (options.count * 2 + 1)
                options.insert(fallback)
            }
        }

        return Array(options).shuffled()
    }
}
