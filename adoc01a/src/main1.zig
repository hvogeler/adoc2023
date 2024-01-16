const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = try readFile(allocator, "/Users/hvo/zig/adoc2023/adoc01a/data/a.txt");

    var sum: u64 = 0;
    for (lines, 1..) |line, idx| {
        const digits = try DigitPair.instance(line);
        sum += digits.getNumber();
        std.debug.print("line {d}: {d} ({d}) ({d}): {s}\n", .{ idx, line.len, digits.getNumber(), sum, line });
    }

    std.debug.print("Sum of calibration values: {d} \n", .{sum});
}

fn readFile(allocator: std.mem.Allocator, filePath: [:0]const u8) ![]const []const u8 {
    const f = try std.fs.openFileAbsolute(filePath, .{ .mode = .read_only });
    defer f.close();
    const reader = f.reader();
    var lines = std.ArrayList([]const u8).init(allocator);
    var line_opt = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 100);
    while (line_opt) |line| {
        try lines.append(line);
        line_opt = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 100);
    }
    return lines.items;
}

const NoDigitError = error{DigitNotFoundError};

const DigitPair = struct {
    first_digit: u8,
    second_digit: u8,

    pub fn getNumber(self: *@This()) u8 {
        return (self.first_digit * 10) + self.second_digit;
    }

    pub fn getFirstAndLastDigit(self: *DigitPair, s: []const u8) !*DigitPair {
        var first_digit: ?u8 = null;
        var second_digit: ?u8 = null;
        loop1: for (s) |c| {
            if (c >= 0x30 and c <= 0x39) {
                first_digit = c - 0x30;
                break :loop1;
            }
        }

        var i = s.len;
        loop2: while (i > 0) {
            const c = s[i - 1];
            if (c >= 0x30 and c <= 0x39) {
                second_digit = c - 0x30;
                break :loop2;
            }
            i -= 1;
        }

        if (first_digit == null or second_digit == null) {
            try std.io.getStdErr().writer().print("No Digit in: {s}\n", .{s});
            return NoDigitError.DigitNotFoundError;
        }
        self.first_digit = first_digit.?;
        self.second_digit = second_digit.?;
        return self;
    }

    pub fn instance(s: []const u8) !*DigitPair {
        var digits = DigitPair{ .first_digit = 0, .second_digit = 0 };
        return try digits.getFirstAndLastDigit(s);
    }
};

test "getFirstAndLastDigit test" {
    var v = DigitPair{ .first_digit = 0, .second_digit = 0 };
    _ = try v.getFirstAndLastDigit("a1bb3cc");
    try std.testing.expect(v.first_digit == 1 and v.second_digit == 3);

    var v1 = try DigitPair.instance("2bb4cc");
    try std.testing.expect(v1.first_digit == 2 and v1.second_digit == 4);

    v1 = try v1.getFirstAndLastDigit("3bb5");
    try std.testing.expect(v1.first_digit == 3 and v1.second_digit == 5);

    v1 = try v1.getFirstAndLastDigit("aa3bb5");
    try std.testing.expect(v1.first_digit == 3 and v1.second_digit == 5);

    v1 = try v1.getFirstAndLastDigit("45");
    try std.testing.expect(v1.first_digit == 4 and v1.second_digit == 5);

    v1 = try v1.getFirstAndLastDigit("485");
    try std.testing.expect(v1.first_digit == 4 and v1.second_digit == 5);

    v1 = try v1.getFirstAndLastDigit("asd4asd8as34d5asd");
    try std.testing.expect(v1.first_digit == 4 and v1.second_digit == 5);

    v1 = try v1.getFirstAndLastDigit("9vxfg");
    try std.testing.expect(v1.first_digit == 9 and v1.second_digit == 9);

    v1 = try v1.getFirstAndLastDigit("asd4asasd");
    try std.testing.expect(v1.first_digit == 4 and v1.second_digit == 4);

    const v2 = v1.getFirstAndLastDigit("asdasasd");
    try std.testing.expectError(NoDigitError.DigitNotFoundError, v2);
}
