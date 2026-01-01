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
        FastingSettings.isFastingTimeNow
    }

    private var eatingWindowStart: Int {
        FastingSettings.startHour(for: .now)
    }

    private var eatingWindowEnd: Int {
        FastingSettings.endHour(for: .now)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        if isFastingTime {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundStyle(.orange)
                                Text("Fasting time active")
                                    .font(.subheadline)
                            }
                        }
                    }

                    Section("Today") {
                        if todayMeals.isEmpty {
                            Text("No meals logged yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(todayMeals, id: \.timestamp) { meal in
                                MealRowView(meal: meal)
                            }
                            .onDelete(perform: deleteMeals)
                        }
                    }
                }

                Button {
                    showingCamera = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Food")
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

                if meal.isOutsideEatingWindow {
                    if meal.isBeforeStartTime {
                        Label("Before \(meal.eatingWindowStart):00", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Label("After \(meal.eatingWindowEnd):00", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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
