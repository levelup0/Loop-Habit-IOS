import Foundation
import SQLite3
import SwiftData

// SQLITE_TRANSIENT tells SQLite to copy the string (safe for Swift strings)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// Maps Android color index → Loop hex color
private let androidColorPalette: [String] = [
    "#D32F2F","#E53935","#F44336","#EF9A9A", // reds
    "#E65100","#EF6C00","#F57C00","#FF9800", // oranges
    "#33691E","#558B2F","#689F38","#8BC34A", // greens
    "#006064","#00838F","#0097A7","#00BCD4", // teals
    "#0D47A1","#1565C0","#1976D2","#42A5F5", // blues
    "#4A148C","#6A1B9A"                       // purples
]

private func colorHex(from androidIndex: Int) -> String {
    let idx = max(0, min(androidIndex, androidColorPalette.count - 1))
    return androidColorPalette[idx]
}

private func androidColorIndex(from hex: String) -> Int {
    androidColorPalette.firstIndex(of: hex.uppercased()) ??
    androidColorPalette.firstIndex(of: hex) ?? 0
}

// ────────────────────────────────────────────────────────────
// MARK: - IMPORT
// ────────────────────────────────────────────────────────────

enum ImportError: LocalizedError {
    case cannotOpenDB(String)
    case queryFailed(String)
    var errorDescription: String? {
        switch self {
        case .cannotOpenDB(let m): return "Cannot open database: \(m)"
        case .queryFailed(let m):  return "Query failed: \(m)"
        }
    }
}

struct ImportResult {
    var habitsImported: Int = 0
    var entriesImported: Int = 0
    var skipped: Int = 0
}

func importFromLoopDB(url: URL, context: ModelContext) throws -> ImportResult {
    var db: OpaquePointer?
    guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
        throw ImportError.cannotOpenDB(String(cString: sqlite3_errmsg(db)))
    }
    defer { sqlite3_close(db) }

    var result = ImportResult()

    // ── 1. Load all habits ──────────────────────────────────
    var habitStmt: OpaquePointer?
    let habitSQL = """
        SELECT id, name, type, color, freq_num, freq_den,
               target_type, target_value, unit, question, description,
               archived, position, reminder_hour, reminder_min, reminder_days,
               uuid
        FROM Habits ORDER BY position
        """
    guard sqlite3_prepare_v2(db, habitSQL, -1, &habitStmt, nil) == SQLITE_OK else {
        throw ImportError.queryFailed("Habits")
    }
    defer { sqlite3_finalize(habitStmt) }

    // id → new Habit mapping for linking repetitions
    var habitMap: [Int64: Habit] = [:]
    // Track existing names to skip duplicates
    let existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
    let existingNames = Set(existing.map { $0.name })

    var sortOrder = existing.count

    while sqlite3_step(habitStmt) == SQLITE_ROW {
        let dbID         = sqlite3_column_int64(habitStmt, 0)
        let name         = colText(habitStmt, 1) ?? "Unnamed"
        let typeRaw      = sqlite3_column_int(habitStmt, 2)
        let colorIdx     = Int(sqlite3_column_int(habitStmt, 3))
        let freqNum      = Int(sqlite3_column_int(habitStmt, 4))
        let freqDen      = Int(sqlite3_column_int(habitStmt, 5))
        let targetTypeRaw = Int(sqlite3_column_int(habitStmt, 6))
        let targetValue  = sqlite3_column_double(habitStmt, 7)
        let unit         = colText(habitStmt, 8) ?? ""
        let question     = colText(habitStmt, 9) ?? ""
        let notes        = colText(habitStmt, 10) ?? ""
        let archived     = sqlite3_column_int(habitStmt, 11) != 0
        let position     = Int(sqlite3_column_int(habitStmt, 12))
        let remHour      = Int(sqlite3_column_int(habitStmt, 13))
        let remMin       = Int(sqlite3_column_int(habitStmt, 14))
        let remDays      = Int(sqlite3_column_int(habitStmt, 15))  // bitmask
        // col 16 = uuid (ignored, we generate our own)

        if existingNames.contains(name) {
            result.skipped += 1
            continue
        }

        let habit = Habit(
            name: name,
            colorHex: colorHex(from: colorIdx),
            sortOrder: sortOrder + position,
            frequencyType: freqType(num: freqNum, den: freqDen, remDays: remDays)
        )
        habit.typeRaw           = Int(typeRaw)
        habit.question          = question
        habit.habitNotes        = notes
        habit.unit              = unit
        habit.targetValue       = targetValue
        habit.targetTypeRaw     = targetTypeRaw
        habit.frequencyNumerator   = freqNum
        habit.frequencyDenominator = freqDen
        habit.isArchived        = archived

        // Decode reminder_days bitmask → daysOfWeek (Loop: 1=Mon…7=Sun)
        // Android bitmask: bit0=Sun, bit1=Mon, ..., bit6=Sat
        if remDays != 0 && remDays != 127 {
            var days: [Int] = []
            // bit1=Mon(1)…bit6=Sat(6), bit0=Sun(7)
            for bit in 1...6 {
                if remDays & (1 << bit) != 0 { days.append(bit) }
            }
            if remDays & 1 != 0 { days.append(7) } // Sunday
            habit.daysOfWeek = days.sorted()
            habit.frequencyTypeRaw = FrequencyType.specificDays.rawValue
        } else if freqDen == 1 && freqNum == 1 {
            habit.frequencyTypeRaw = FrequencyType.everyDay.rawValue
        }

        // Reminder (only if hour column is not null/0)
        if remHour > 0 || (remHour == 0 && remMin > 0) {
            habit.reminderHour   = remHour
            habit.reminderMinute = remMin
        }

        context.insert(habit)
        habitMap[dbID] = habit
        result.habitsImported += 1
    }

    // ── 2. Load repetitions ─────────────────────────────────
    var repStmt: OpaquePointer?
    let repSQL = "SELECT habit, timestamp, value, notes FROM Repetitions ORDER BY timestamp"
    guard sqlite3_prepare_v2(db, repSQL, -1, &repStmt, nil) == SQLITE_OK else {
        throw ImportError.queryFailed("Repetitions")
    }
    defer { sqlite3_finalize(repStmt) }

    while sqlite3_step(repStmt) == SQLITE_ROW {
        let habitDBID = sqlite3_column_int64(repStmt, 0)
        let tsMs      = sqlite3_column_int64(repStmt, 1)  // unix ms
        let value     = sqlite3_column_int64(repStmt, 2)
        let notes     = colText(repStmt, 3) ?? ""

        guard let habit = habitMap[habitDBID] else { continue }

        let date = Date(timeIntervalSince1970: Double(tsMs) / 1000.0)
        let dayStart = Calendar.current.startOfDay(for: date)

        var entry: HabitEntry
        if habit.habitType == .measurable {
            // Measurable: value is stored ×1000 in Android
            let numeric = Double(value) / 1000.0
            entry = HabitEntry(habitID: habit.id, date: dayStart, numericValue: numeric, notes: notes)
        } else {
            // Yes/No: value is CheckmarkValue (2=YES_MANUAL, 3=SKIP)
            let cv = CheckmarkValue(rawValue: Int(value)) ?? .yesManual
            entry = HabitEntry(habitID: habit.id, date: dayStart, value: cv, notes: notes)
        }

        context.insert(entry)
        habit.entries.append(entry)
        result.entriesImported += 1
    }

    try context.save()
    return result
}

// ────────────────────────────────────────────────────────────
// MARK: - EXPORT
// ────────────────────────────────────────────────────────────

enum ExportError: LocalizedError {
    case cannotCreateDB(String)
    case execFailed(String)
    var errorDescription: String? {
        switch self {
        case .cannotCreateDB(let m): return "Cannot create database: \(m)"
        case .execFailed(let m):     return "SQL exec failed: \(m)"
        }
    }
}

func exportToLoopDB(habits: [Habit], to url: URL) throws {
    // Remove existing file
    try? FileManager.default.removeItem(at: url)

    var db: OpaquePointer?
    guard sqlite3_open(url.path, &db) == SQLITE_OK else {
        throw ExportError.cannotCreateDB(String(cString: sqlite3_errmsg(db)))
    }
    defer { sqlite3_close(db) }

    func exec(_ sql: String) throws {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw ExportError.execFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    // Create tables matching Android schema exactly
    try exec("""
        CREATE TABLE android_metadata (locale TEXT);
        INSERT INTO android_metadata VALUES ('en_US');
        """)

    try exec("""
        CREATE TABLE Habits (
            id integer primary key autoincrement,
            archived integer,
            color integer,
            description text,
            freq_den integer,
            freq_num integer,
            highlight integer,
            name text,
            position integer,
            reminder_hour integer,
            reminder_min integer,
            reminder_days integer not null default 127,
            type integer not null default 0,
            target_type integer not null default 0,
            target_value real not null default 0,
            unit text not null default '',
            question text,
            uuid text
        );
        """)

    try exec("""
        CREATE TABLE Repetitions (
            id integer primary key autoincrement,
            habit integer not null references Habits(id),
            timestamp integer not null,
            value integer not null,
            notes text
        );
        CREATE UNIQUE INDEX idx_repetitions_habit_timestamp
            ON Repetitions(habit, timestamp);
        """)

    try exec("""
        CREATE TABLE Events (
            id integer primary key autoincrement,
            habit integer references Habits(id),
            timestamp integer,
            type integer,
            message text
        );
        """)

    // Insert habits
    var habitStmt: OpaquePointer?
    let habitSQL = """
        INSERT INTO Habits
        (archived, color, description, freq_den, freq_num, highlight,
         name, position, reminder_hour, reminder_min, reminder_days,
         type, target_type, target_value, unit, question, uuid)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
    sqlite3_prepare_v2(db, habitSQL, -1, &habitStmt, nil)
    defer { sqlite3_finalize(habitStmt) }

    var dbIDMap: [UUID: Int64] = [:]  // habit.id → SQLite rowid

    for (pos, habit) in habits.enumerated() {
        sqlite3_reset(habitStmt)
        sqlite3_bind_int(habitStmt,  1, habit.isArchived ? 1 : 0)
        sqlite3_bind_int(habitStmt,  2, Int32(androidColorIndex(from: habit.colorHex)))
        sqlite3_bind_text(habitStmt, 3, habit.habitNotes, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(habitStmt,  4, Int32(habit.frequencyDenominator))
        sqlite3_bind_int(habitStmt,  5, Int32(habit.frequencyNumerator))
        sqlite3_bind_int(habitStmt,  6, 0)
        sqlite3_bind_text(habitStmt, 7, habit.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(habitStmt,  8, Int32(pos))
        if habit.reminderHour >= 0 {
            sqlite3_bind_int(habitStmt, 9,  Int32(habit.reminderHour))
            sqlite3_bind_int(habitStmt, 10, Int32(habit.reminderMinute))
        } else {
            sqlite3_bind_null(habitStmt, 9)
            sqlite3_bind_null(habitStmt, 10)
        }
        sqlite3_bind_int(habitStmt, 11, Int32(reminderDaysMask(habit.daysOfWeek)))
        sqlite3_bind_int(habitStmt, 12, Int32(habit.typeRaw))
        sqlite3_bind_int(habitStmt, 13, Int32(habit.targetTypeRaw))
        sqlite3_bind_double(habitStmt, 14, habit.targetValue)
        sqlite3_bind_text(habitStmt, 15, habit.unit, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(habitStmt, 16, habit.question, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(habitStmt, 17, habit.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_step(habitStmt)
        dbIDMap[habit.id] = sqlite3_last_insert_rowid(db)
    }

    // Insert repetitions
    var repStmt: OpaquePointer?
    let repSQL = "INSERT INTO Repetitions (habit, timestamp, value, notes) VALUES (?,?,?,?)"
    sqlite3_prepare_v2(db, repSQL, -1, &repStmt, nil)
    defer { sqlite3_finalize(repStmt) }

    for habit in habits {
        guard let dbID = dbIDMap[habit.id] else { continue }
        for entry in habit.entries {
            let tsMs = Int64(entry.date.timeIntervalSince1970 * 1000)
            let value: Int64
            if habit.habitType == .measurable {
                // Measurable: store ×1000
                value = Int64(entry.numericValue * 1000)
            } else {
                value = Int64(entry.value)
            }
            sqlite3_reset(repStmt)
            sqlite3_bind_int64(repStmt, 1, dbID)
            sqlite3_bind_int64(repStmt, 2, tsMs)
            sqlite3_bind_int64(repStmt, 3, value)
            sqlite3_bind_text(repStmt,  4, entry.entryNotes, -1, SQLITE_TRANSIENT)
            sqlite3_step(repStmt)
        }
    }
}

// ────────────────────────────────────────────────────────────
// MARK: - Helpers
// ────────────────────────────────────────────────────────────

private func colText(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
    guard let ptr = sqlite3_column_text(stmt, col) else { return nil }
    return String(cString: ptr)
}

private func freqType(num: Int, den: Int, remDays: Int) -> FrequencyType {
    if remDays != 0 && remDays != 127 { return .specificDays }
    if num == 1 && den == 1  { return .everyDay }
    if den == 1              { return .everyNDays }
    if den == 7              { return .timesPerWeek }
    if den == 30 || den == 31 { return .timesPerMonth }
    return .timesInPeriod
}

// Loop daysOfWeek (1=Mon…7=Sun) → Android bitmask (bit0=Sun, bit1=Mon…bit6=Sat)
private func reminderDaysMask(_ days: [Int]) -> Int {
    guard !days.isEmpty else { return 127 }
    var mask = 0
    for d in days {
        let bit = d == 7 ? 0 : d  // Sun=0, Mon=1…Sat=6
        mask |= (1 << bit)
    }
    return mask
}
