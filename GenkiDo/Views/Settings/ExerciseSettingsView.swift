import SwiftUI
import SwiftData

struct ExerciseSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomExercise.sortOrder) private var allExercises: [CustomExercise]
    @State private var editingExercise: CustomExercise?
    @State private var showingAddSheet = false
    @State private var isEditing = false

    private var activeExercises: [CustomExercise] {
        allExercises.filter { $0.isActive }
    }

    private var inactiveExercises: [CustomExercise] {
        allExercises.filter { !$0.isActive }
    }

    var body: some View {
        List {
            Section {
                ForEach(activeExercises) { exercise in
                    ExerciseRow(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingExercise = exercise
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                ExerciseService.deactivateExercise(exercise, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove(perform: moveExercise)
            } header: {
                Text("Active Exercises")
            } footer: {
                Text("Tap to edit. Hold and drag to reorder.")
            }

            if !inactiveExercises.isEmpty {
                Section("Inactive Exercises") {
                    ForEach(inactiveExercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Activate") {
                                ExerciseService.activateExercise(exercise, context: modelContext)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                }
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Exercises")
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .toolbar {
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
        }
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditSheet(exercise: exercise, isNew: false)
        }
        .sheet(isPresented: $showingAddSheet) {
            ExerciseEditSheet(exercise: nil, isNew: true)
        }
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        var exercises = activeExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        ExerciseService.updateSortOrders(exercises, context: modelContext)
    }
}

struct ExerciseRow: View {
    let exercise: CustomExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var subtitleText: String {
        switch exercise.exerciseType {
        case .reps:
            return "\(exercise.goal) reps"
        case .timed:
            return "\(exercise.goal) seconds"
        case .done:
            return "Completion status"
        }
    }
}

struct ExerciseEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exercise: CustomExercise?
    let isNew: Bool

    @State private var name: String = ""
    @State private var type: ExerciseType = .reps
    @State private var goal: Int = 50

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if type != .done {
                    Section(type == .timed ? "Time (seconds)" : "Repetitions") {
                        Stepper("\(goal)", value: $goal, in: 1...999)
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            if let exercise = exercise {
                                ExerciseService.deactivateExercise(exercise, context: modelContext)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Deactivate")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let exercise = exercise {
                    name = exercise.name
                    type = exercise.exerciseType
                    goal = exercise.goal
                }
            }
        }
    }

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let exercise = exercise {
            exercise.name = trimmedName
            exercise.exerciseType = type
            exercise.goal = type == .done ? 1 : goal
            try? modelContext.save()
        } else {
            _ = ExerciseService.createExercise(
                name: trimmedName,
                type: type,
                goal: type == .done ? 1 : goal,
                context: modelContext
            )
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseSettingsView()
    }
    .modelContainer(for: CustomExercise.self, inMemory: true)
}
