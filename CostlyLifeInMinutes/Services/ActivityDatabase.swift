import Foundation

struct ActivityDatabase {
    static let all: [Activity] = [
        Activity(id: "cigarette", name: "Cigarette", icon: "smoke", minutesDelta: -11, category: .substance),
        Activity(id: "vape", name: "Vape Hit", icon: "wind", minutesDelta: -5, category: .substance),
        Activity(id: "alcohol_beer", name: "Beer", icon: "mug", minutesDelta: -7, category: .substance),
        Activity(id: "alcohol_wine", name: "Glass of Wine", icon: "wineglass", minutesDelta: -5, category: .substance),
        Activity(id: "alcohol_spirit", name: "Spirit Shot", icon: "drop.triangle", minutesDelta: -9, category: .substance),
        Activity(id: "cannabis", name: "Cannabis", icon: "leaf", minutesDelta: -8, category: .substance),

        Activity(id: "coffee", name: "Coffee", icon: "cup.and.saucer", minutesDelta: -2, category: .food),
        Activity(id: "green_tea", name: "Green Tea", icon: "cup.and.saucer.fill", minutesDelta: +3, category: .food),
        Activity(id: "water", name: "Glass of Water", icon: "drop", minutesDelta: +1, category: .food),
        Activity(id: "soda", name: "Soda", icon: "takeoutbag.and.cup.and.straw", minutesDelta: -5, category: .food),
        Activity(id: "energy_drink", name: "Energy Drink", icon: "bolt", minutesDelta: -7, category: .food),
        Activity(id: "fast_food", name: "Fast Food Meal", icon: "fork.knife", minutesDelta: -15, category: .food),
        Activity(id: "salad", name: "Salad", icon: "carrot", minutesDelta: +4, category: .food),
        Activity(id: "fruit", name: "Fresh Fruit", icon: "apple.logo", minutesDelta: +3, category: .food),
        Activity(id: "processed_snack", name: "Processed Snack", icon: "bag", minutesDelta: -4, category: .food),
        Activity(id: "home_cooked", name: "Home-Cooked Meal", icon: "frying.pan", minutesDelta: +5, category: .food),
        Activity(id: "smoothie", name: "Green Smoothie", icon: "blender", minutesDelta: +4, category: .food),

        Activity(id: "run_30", name: "30-min Run", icon: "figure.run", minutesDelta: +26, category: .exercise),
        Activity(id: "walk_30", name: "30-min Walk", icon: "figure.walk", minutesDelta: +11, category: .exercise),
        Activity(id: "gym_60", name: "Gym Session", icon: "dumbbell", minutesDelta: +30, category: .exercise),
        Activity(id: "yoga_30", name: "Yoga Session", icon: "figure.yoga", minutesDelta: +15, category: .exercise),
        Activity(id: "swim_30", name: "Swimming", icon: "figure.pool.swim", minutesDelta: +22, category: .exercise),
        Activity(id: "cycling_30", name: "30-min Cycling", icon: "figure.outdoor.cycle", minutesDelta: +20, category: .exercise),
        Activity(id: "stretching", name: "Stretching", icon: "figure.flexibility", minutesDelta: +5, category: .exercise),

        Activity(id: "meditation_15", name: "15-min Meditation", icon: "brain.head.profile", minutesDelta: +12, category: .wellness),
        Activity(id: "cold_shower", name: "Cold Shower", icon: "shower", minutesDelta: +5, category: .wellness),
        Activity(id: "journaling", name: "Journaling", icon: "book.closed", minutesDelta: +4, category: .wellness),
        Activity(id: "gratitude", name: "Gratitude Practice", icon: "hands.clap", minutesDelta: +3, category: .wellness),
        Activity(id: "deep_breathing", name: "Deep Breathing", icon: "lungs", minutesDelta: +6, category: .wellness),
        Activity(id: "sunlight", name: "Morning Sunlight", icon: "sun.max", minutesDelta: +5, category: .wellness),

        Activity(id: "sleep_8h", name: "8 Hours Sleep", icon: "bed.double", minutesDelta: +15, category: .sleep),
        Activity(id: "sleep_6h", name: "6 Hours Sleep", icon: "bed.double.fill", minutesDelta: -10, category: .sleep),
        Activity(id: "nap", name: "Power Nap", icon: "moon.zzz", minutesDelta: +5, category: .sleep),
        Activity(id: "sleep_deprivation", name: "All-Nighter", icon: "moon", minutesDelta: -25, category: .sleep),

        Activity(id: "sitting_prolonged", name: "Prolonged Sitting", icon: "chair.lounge", minutesDelta: -8, category: .lifestyle),
        Activity(id: "screen_time", name: "Extra Screen Time", icon: "iphone", minutesDelta: -3, category: .lifestyle),
        Activity(id: "social_connection", name: "Quality Social Time", icon: "person.2", minutesDelta: +8, category: .lifestyle),
        Activity(id: "nature", name: "Time in Nature", icon: "tree", minutesDelta: +10, category: .lifestyle),
        Activity(id: "reading", name: "Reading", icon: "book", minutesDelta: +4, category: .lifestyle),
        Activity(id: "stress", name: "High Stress Event", icon: "exclamationmark.triangle", minutesDelta: -12, category: .lifestyle),
        Activity(id: "laughter", name: "Good Laugh", icon: "face.smiling", minutesDelta: +3, category: .lifestyle),
    ]

    static func search(_ query: String) -> [Activity] {
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedStandardContains(query) }
    }

    static func byCategory() -> [(category: ActivityCategory, activities: [Activity])] {
        ActivityCategory.allCases.compactMap { category in
            let activities = all.filter { $0.category == category }
            return activities.isEmpty ? nil : (category, activities)
        }
    }

    static func activity(for id: String) -> Activity? {
        all.first { $0.id == id }
    }
}
