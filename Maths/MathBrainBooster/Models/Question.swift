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
            b = Int.random(in: 1...max(1, multRange.upperBound))
            answer = Int.random(in: 1...max(1, multRange.upperBound))
            a = b * answer
            text = "\(a) ÷ \(b)"
        default:
            a = Int.random(in: range)
            b = Int.random(in: range)
            answer = a + b
            text = "\(a) + \(b)"
        }

        let options = generateOptions(correctAnswer: answer, count: 4)
        return Question(text: text, correctAnswer: answer, options: options)
    }

    private static func generateTrueFalse(mode: GameMode, difficulty: Difficulty) -> Question {
        let range = difficulty.numberRange
        let multRange = difficulty.multiplicationRange
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
            b = Int.random(in: 1...max(1, multRange.upperBound))
            correctAnswer = Int.random(in: 1...max(1, multRange.upperBound))
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
            var wrong = correctAnswer + Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
            if wrong == correctAnswer { wrong += 1 }
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

    private static func generateOptions(correctAnswer: Int, count: Int) -> [Int] {
        var options = Set<Int>()
        options.insert(correctAnswer)

        let offsets = [-3, -2, -1, 1, 2, 3, 4, 5, -4, -5]
        var shuffledOffsets = offsets.shuffled()

        while options.count < count {
            if let offset = shuffledOffsets.popLast() {
                let option = correctAnswer + offset
                if option >= 0 {
                    options.insert(option)
                }
            } else {
                options.insert(correctAnswer + options.count + 1)
            }
        }

        return Array(options).shuffled()
    }
}
