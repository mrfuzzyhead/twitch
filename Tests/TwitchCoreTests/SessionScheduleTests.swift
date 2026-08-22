import XCTest
@testable import TwitchCore

final class SessionScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testFutureHourUsesSameDay() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 22, hour: 10, minute: 30
        )))
        let result = try XCTUnwrap(SessionSchedule.nextOccurrence(
            ofHour: 17,
            after: now,
            calendar: calendar
        ))

        XCTAssertEqual(calendar.component(.day, from: result), 22)
        XCTAssertEqual(calendar.component(.hour, from: result), 17)
        XCTAssertEqual(calendar.component(.minute, from: result), 0)
    }

    func testPastHourUsesFollowingDay() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 22, hour: 18, minute: 30
        )))
        let result = try XCTUnwrap(SessionSchedule.nextOccurrence(
            ofHour: 12,
            after: now,
            calendar: calendar
        ))

        XCTAssertEqual(calendar.component(.day, from: result), 23)
        XCTAssertEqual(calendar.component(.hour, from: result), 12)
    }

    func testHourLabelsCoverMidnightNoonAndEvening() {
        XCTAssertEqual(SessionSchedule.hourLabel(for: 0), "12am")
        XCTAssertEqual(SessionSchedule.hourLabel(for: 12), "12pm")
        XCTAssertEqual(SessionSchedule.hourLabel(for: 23), "11pm")
    }
}
