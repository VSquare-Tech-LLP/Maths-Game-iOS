import Foundation

struct AdvancedMathQuestion: Identifiable {
    let id = UUID()
    let text: String
    let correctAnswer: Int
    let options: [Int]

    // MARK: - Generate

    static func generate(type: AdvancedMathType, difficulty: Difficulty) -> AdvancedMathQuestion {
        switch type {
        case .integers:  return generateIntegers(difficulty: difficulty)
        case .squares:   return generateSquares(difficulty: difficulty)
        case .decimals:  return generateDecimals(difficulty: difficulty)
        case .percents:  return generatePercents(difficulty: difficulty)
        }
    }

    // MARK: - Integers (positive & negative number operations)

    private static func generateIntegers(difficulty: Difficulty) -> AdvancedMathQuestion {
        let maxVal: Int
        let ops: [String]

        switch difficulty {
        case .easy:
            maxVal = 10
            ops = ["+", "-"]
        case .medium:
            maxVal = 25
            ops = ["+", "-", "×"]
        case .hard:
            maxVal = 50
            ops = ["+", "-", "×"]
        case .expert:
            maxVal = 100
            ops = ["+", "-", "×"]
        }

        let a = Int.random(in: -maxVal...maxVal)
        let b = Int.random(in: -maxVal...maxVal)
        let op = ops.randomElement()!
        var answer: Int
        var text: String

        // Format negative numbers with parentheses
        let aStr = a < 0 ? "(\(a))" : "\(a)"
        let bStr = b < 0 ? "(\(b))" : "\(b)"

        switch op {
        case "+":
            answer = a + b
            text = "\(aStr) + \(bStr)"
        case "-":
            answer = a - b
            text = "\(aStr) - \(bStr)"
        case "×":
            // Keep multiplication numbers smaller to stay reasonable
            let ma = Int.random(in: -min(maxVal, 15)...min(maxVal, 15))
            let mb = Int.random(in: -min(maxVal, 12)...min(maxVal, 12))
            answer = ma * mb
            let maStr = ma < 0 ? "(\(ma))" : "\(ma)"
            let mbStr = mb < 0 ? "(\(mb))" : "\(mb)"
            text = "\(maStr) × \(mbStr)"
        default:
            answer = a + b
            text = "\(aStr) + \(bStr)"
        }

        let options = generateIntegerOptions(correctAnswer: answer, difficulty: difficulty)
        return AdvancedMathQuestion(text: text, correctAnswer: answer, options: options)
    }

    // MARK: - Squares & Powers

    private static func generateSquares(difficulty: Difficulty) -> AdvancedMathQuestion {
        let text: String
        let answer: Int

        switch difficulty {
        case .easy:
            // Simple squares: n² where n = 1..12
            let n = Int.random(in: 1...12)
            answer = n * n
            text = "\(n)²"

        case .medium:
            // Squares up to 20, some cubes
            if Bool.random() {
                let n = Int.random(in: 5...20)
                answer = n * n
                text = "\(n)²"
            } else {
                let n = Int.random(in: 2...8)
                answer = n * n * n
                text = "\(n)³"
            }

        case .hard:
            let roll = Int.random(in: 0...2)
            if roll == 0 {
                // Larger squares
                let n = Int.random(in: 12...30)
                answer = n * n
                text = "\(n)²"
            } else if roll == 1 {
                // Cubes
                let n = Int.random(in: 3...12)
                answer = n * n * n
                text = "\(n)³"
            } else {
                // Square root (perfect squares)
                let root = Int.random(in: 4...20)
                let sq = root * root
                answer = root
                text = "√\(sq)"
            }

        case .expert:
            let roll = Int.random(in: 0...3)
            if roll == 0 {
                // Large squares
                let n = Int.random(in: 20...50)
                answer = n * n
                text = "\(n)²"
            } else if roll == 1 {
                // Larger cubes
                let n = Int.random(in: 5...15)
                answer = n * n * n
                text = "\(n)³"
            } else if roll == 2 {
                // Square roots of larger numbers
                let root = Int.random(in: 10...35)
                let sq = root * root
                answer = root
                text = "√\(sq)"
            } else {
                // Power of 4 (small base)
                let n = Int.random(in: 2...6)
                answer = n * n * n * n
                text = "\(n)⁴"
            }
        }

        let options = generateOptions(correctAnswer: answer, spread: spreadFor(difficulty), count: 4)
        return AdvancedMathQuestion(text: text, correctAnswer: answer, options: options)
    }

    // MARK: - Decimal Fractions

    private static func generateDecimals(difficulty: Difficulty) -> AdvancedMathQuestion {
        // We work in "integer tenths/hundredths" then display as decimals
        // Answer is always integer (multiply result to avoid floating point)
        let text: String
        let answer: Int

        switch difficulty {
        case .easy:
            // a.b + c.d   (one decimal place, small numbers)
            let a = Int.random(in: 1...50)  // represents 0.1 to 5.0
            let b = Int.random(in: 1...50)
            let op = ["+", "-"].randomElement()!
            if op == "+" {
                answer = a + b
                text = "\(decStr(a)) + \(decStr(b))"
            } else {
                let big = max(a, b)
                let small = min(a, b)
                answer = big - small
                text = "\(decStr(big)) - \(decStr(small))"
            }

        case .medium:
            let a = Int.random(in: 10...150)  // 1.0 to 15.0
            let b = Int.random(in: 10...150)
            let op = ["+", "-"].randomElement()!
            if op == "+" {
                answer = a + b
                text = "\(decStr(a)) + \(decStr(b))"
            } else {
                let big = max(a, b)
                let small = min(a, b)
                answer = big - small
                text = "\(decStr(big)) - \(decStr(small))"
            }

        case .hard:
            // Multiplication: a.b × c  (decimal × integer)
            let roll = Int.random(in: 0...1)
            if roll == 0 {
                let a = Int.random(in: 10...100)
                let b = Int.random(in: 10...100)
                let op = ["+", "-"].randomElement()!
                if op == "+" {
                    answer = a + b
                } else {
                    let big = max(a, b)
                    let small = min(a, b)
                    text = "\(decStr(big)) - \(decStr(small))"
                    return AdvancedMathQuestion(
                        text: "\(decStr(big)) - \(decStr(small))",
                        correctAnswer: big - small,
                        options: generateDecimalOptions(correctAnswer: big - small, difficulty: difficulty)
                    )
                }
                text = "\(decStr(a)) + \(decStr(b))"
            } else {
                // decimal × whole number
                let d = Int.random(in: 1...30)   // 0.1 to 3.0
                let w = Int.random(in: 2...9)
                answer = d * w
                text = "\(decStr(d)) × \(w)"
            }

        case .expert:
            let roll = Int.random(in: 0...2)
            if roll == 0 {
                // Larger add/sub
                let a = Int.random(in: 50...500)
                let b = Int.random(in: 50...500)
                if Bool.random() {
                    answer = a + b
                    text = "\(decStr(a)) + \(decStr(b))"
                } else {
                    let big = max(a, b)
                    let small = min(a, b)
                    answer = big - small
                    text = "\(decStr(big)) - \(decStr(small))"
                }
            } else if roll == 1 {
                // decimal × whole
                let d = Int.random(in: 10...80)
                let w = Int.random(in: 3...12)
                answer = d * w
                text = "\(decStr(d)) × \(w)"
            } else {
                // decimal × decimal (both have 1 decimal place, answer in hundredths)
                // Keep simpler: a.b × c.d where result is whole-ish
                let d1 = Int.random(in: 2...15)  // tenths
                let d2 = Int.random(in: 2...10)
                answer = d1 * d2  // result is in hundredths, display as tenths × tenths = hundredths
                text = "\(decStr(d1)) × \(decStr(d2))"
            }
        }

        let options = generateDecimalOptions(correctAnswer: answer, difficulty: difficulty)
        return AdvancedMathQuestion(text: text, correctAnswer: answer, options: options)
    }

    // MARK: - Percents

    private static func generatePercents(difficulty: Difficulty) -> AdvancedMathQuestion {
        let text: String
        let answer: Int

        switch difficulty {
        case .easy:
            // Simple percents: 10%, 20%, 25%, 50% of round numbers
            let percents = [10, 20, 25, 50]
            let p = percents.randomElement()!
            let base = Int.random(in: 1...10) * 10  // 10, 20, ..., 100
            answer = base * p / 100
            text = "\(p)% of \(base)"

        case .medium:
            // More percents: 5%, 10%, 15%, 20%, 25%, 30%, 50%, 75%
            let percents = [5, 10, 15, 20, 25, 30, 50, 75]
            let p = percents.randomElement()!
            let base = Int.random(in: 2...20) * 10  // 20 to 200
            answer = base * p / 100
            text = "\(p)% of \(base)"

        case .hard:
            let roll = Int.random(in: 0...1)
            if roll == 0 {
                // Any common percent of larger numbers
                let percents = [5, 10, 12, 15, 20, 25, 30, 40, 50, 60, 75, 80]
                let p = percents.randomElement()!
                let base = Int.random(in: 5...50) * 10  // 50 to 500
                answer = base * p / 100
                text = "\(p)% of \(base)"
            } else {
                // "What percent is A of B?"  A/B × 100
                let percents = [10, 20, 25, 30, 40, 50, 60, 75, 80]
                let p = percents.randomElement()!
                let base = Int.random(in: 5...30) * 10
                let part = base * p / 100
                answer = p
                text = "\(part) is ?% of \(base)"
            }

        case .expert:
            let roll = Int.random(in: 0...2)
            if roll == 0 {
                // Tricky percents of large numbers
                let percents = [5, 8, 12, 15, 18, 20, 25, 30, 35, 40, 45, 50, 60, 75, 80, 90]
                let p = percents.randomElement()!
                let base = Int.random(in: 10...100) * 10  // 100 to 1000
                answer = base * p / 100
                text = "\(p)% of \(base)"
            } else if roll == 1 {
                // "What percent is A of B?"
                let percents = [5, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 75, 80, 90]
                let p = percents.randomElement()!
                let base = Int.random(in: 10...50) * 10
                let part = base * p / 100
                answer = p
                text = "\(part) is ?% of \(base)"
            } else {
                // Increase/decrease: "120 increased by 25% = ?"
                let percents = [10, 20, 25, 50]
                let p = percents.randomElement()!
                let base = Int.random(in: 5...40) * 10
                if Bool.random() {
                    answer = base + (base * p / 100)
                    text = "\(base) + \(p)%"
                } else {
                    answer = base - (base * p / 100)
                    text = "\(base) - \(p)%"
                }
            }
        }

        let options = generateOptions(correctAnswer: answer, spread: spreadFor(difficulty), count: 4)
        return AdvancedMathQuestion(text: text, correctAnswer: answer, options: options)
    }

    // MARK: - Helpers

    /// Format tenths: 15 → "1.5", 7 → "0.7", 120 → "12.0"
    private static func decStr(_ tenths: Int) -> String {
        let whole = tenths / 10
        let frac = abs(tenths % 10)
        return "\(whole).\(frac)"
    }

    private static func spreadFor(_ difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:   return 5
        case .medium: return 10
        case .hard:   return 20
        case .expert: return 30
        }
    }

    // General option generator
    private static func generateOptions(correctAnswer: Int, spread: Int, count: Int) -> [Int] {
        var options = Set<Int>()
        options.insert(correctAnswer)

        var attempts = 0
        while options.count < count && attempts < 50 {
            attempts += 1
            let offset = Int.random(in: 1...max(1, spread))
            let sign = Bool.random() ? 1 : -1
            let option = correctAnswer + offset * sign
            if !options.contains(option) {
                options.insert(option)
            }
        }

        // Fallback
        while options.count < count {
            options.insert(correctAnswer + options.count * 3)
        }

        return Array(options).shuffled()
    }

    // Integer options (can be negative)
    private static func generateIntegerOptions(correctAnswer: Int, difficulty: Difficulty) -> [Int] {
        let spread = spreadFor(difficulty)
        var options = Set<Int>()
        options.insert(correctAnswer)

        // Add sign-flipped answer as a distractor for integers
        if correctAnswer != 0 && !options.contains(-correctAnswer) {
            options.insert(-correctAnswer)
        }

        var attempts = 0
        while options.count < 4 && attempts < 50 {
            attempts += 1
            let offset = Int.random(in: 1...max(1, spread))
            let sign = Bool.random() ? 1 : -1
            let option = correctAnswer + offset * sign
            if !options.contains(option) {
                options.insert(option)
            }
        }

        while options.count < 4 {
            options.insert(correctAnswer + options.count * 2)
        }

        return Array(options).shuffled()
    }

    // Decimal options (close values in tenths)
    private static func generateDecimalOptions(correctAnswer: Int, difficulty: Difficulty) -> [Int] {
        let spread: Int
        switch difficulty {
        case .easy:   spread = 5
        case .medium: spread = 8
        case .hard:   spread = 12
        case .expert: spread = 20
        }

        var options = Set<Int>()
        options.insert(correctAnswer)

        var attempts = 0
        while options.count < 4 && attempts < 50 {
            attempts += 1
            let offset = Int.random(in: 1...max(1, spread))
            let sign = Bool.random() ? 1 : -1
            let option = correctAnswer + offset * sign
            if option >= 0 && !options.contains(option) {
                options.insert(option)
            }
        }

        while options.count < 4 {
            options.insert(correctAnswer + options.count * 2)
        }

        return Array(options).shuffled()
    }
}
