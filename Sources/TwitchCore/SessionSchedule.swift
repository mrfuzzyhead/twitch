import Foundation

public enum SessionSchedule {
    /// Lists all 24 hours starting with the next whole hour, wrapping at midnight.
    public static func upcomingHours(
        after date: Date,
        calendar: Calendar = .current
    ) -> [Int] {
        let currentHour = calendar.component(.hour, from: date)
        return (1...24).map { (currentHour + $0) % 24 }
    }

    /// Returns the next occurrence of the selected whole hour.
    /// If that hour has already started today, the result is tomorrow.
    public static func nextOccurrence(
        ofHour hour: Int,
        after date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard (0...23).contains(hour) else { return nil }

        return calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, minute: 0, second: 0),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

    public static func hourLabel(for hour: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour)\(hour < 12 ? "am" : "pm")"
    }
}
