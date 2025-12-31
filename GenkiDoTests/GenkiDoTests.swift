import Testing
@testable import GenkiDo

@Suite("Exercise Tests")
struct ExerciseTests {
    @Test("Daily goal is 50")
    func dailyGoal() {
        #expect(Exercise.dailyGoal == 50)
    }

    @Test("All exercise types exist")
    func allExerciseTypes() {
        #expect(Exercise.allCases.count == 4)
    }

    @Test("Exercise display names are in German")
    func displayNames() {
        #expect(Exercise.pushUps.displayName == "Liegestütze")
        #expect(Exercise.shoulderRaises.displayName == "Schulterheber")
        #expect(Exercise.squats.displayName == "Kniebeugen")
        #expect(Exercise.crunches.displayName == "Rumpfbeugen")
    }
}

@Suite("ExerciseRecord Tests")
struct ExerciseRecordTests {
    @Test("Record is completed at 50")
    func completedAt50() {
        let record = ExerciseRecord(exercise: .pushUps, count: 50)
        #expect(record.isCompleted)
    }

    @Test("Record is not completed below 50")
    func notCompletedBelow50() {
        let record = ExerciseRecord(exercise: .pushUps, count: 49)
        #expect(!record.isCompleted)
    }

    @Test("Progress calculation")
    func progressCalculation() {
        let record = ExerciseRecord(exercise: .pushUps, count: 25)
        #expect(record.progress == 0.5)
    }

    @Test("Progress caps at 1.0")
    func progressCapped() {
        let record = ExerciseRecord(exercise: .pushUps, count: 100)
        #expect(record.progress == 1.0)
    }
}

@Suite("Meal Tests")
struct MealTests {
    @Test("Meal after 18:00 is marked as fasting violation")
    func afterFastingCutoff() {
        var components = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = 19
        components.minute = 0
        let date = Calendar.current.date(from: components)!

        let meal = Meal(timestamp: date)
        #expect(meal.isAfterFastingCutoff)
    }

    @Test("Meal before 18:00 is not a fasting violation")
    func beforeFastingCutoff() {
        var components = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = 12
        components.minute = 0
        let date = Calendar.current.date(from: components)!

        let meal = Meal(timestamp: date)
        #expect(!meal.isAfterFastingCutoff)
    }
}
