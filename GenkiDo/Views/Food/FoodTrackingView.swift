import SwiftUI
import SwiftData

struct FoodTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var showingCamera = false

    private var todayMeals: [Meal] {
        let today = Calendar.current.startOfDay(for: .now)
        return meals.filter { Calendar.current.startOfDay(for: $0.timestamp) == today }
    }

    private var isFastingTime: Bool {
        Calendar.current.component(.hour, from: .now) >= 18
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if isFastingTime {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.orange)
                            Text("Fastenzeit aktiv")
                                .font(.subheadline)
                        }
                    }
                }

                Section("Heute") {
                    if todayMeals.isEmpty {
                        Text("Noch keine Mahlzeiten erfasst")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todayMeals, id: \.timestamp) { meal in
                            MealRowView(meal: meal)
                        }
                        .onDelete(perform: deleteMeals)
                    }
                }
            }
            .navigationTitle("Essen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Mahlzeit", systemImage: "camera.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    saveMeal(with: image)
                }
                .ignoresSafeArea()
            }
        }
    }

    private func saveMeal(with image: UIImage) {
        guard let compressedData = ImageCompressor.compress(image) else { return }
        let meal = Meal(timestamp: .now, photoData: compressedData)
        modelContext.insert(meal)
    }

    private func deleteMeals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todayMeals[index])
        }
    }
}

struct MealRowView: View {
    let meal: Meal

    var body: some View {
        HStack {
            if let data = meal.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading) {
                Text(meal.timestamp, style: .time)
                    .font(.headline)

                if meal.isAfterFastingCutoff {
                    Label("Nach 18:00", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
    }
}

#Preview {
    FoodTrackingView()
        .modelContainer(for: Meal.self, inMemory: true)
}
