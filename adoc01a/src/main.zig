const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = try readFile(allocator, "/Users/hvo/zig/adoc01a/data/a.txt");

    var sum: u64 = 0;
    for (lines, 1..) |line, idx| {
        const digits = try getFirstAndLastDigit(line);
        std.debug.print("line {d}: {d} ({d}{d}): {s}\n", .{ idx, line.len, digits.a, digits.b, line });
        sum += ((digits.a * 10) + digits.b);
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

fn getFirstAndLastDigit(s: []const u8) !(struct { a: u8, b: u8 }) {
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
    return .{ .a = first_digit.?, .b = second_digit.? };
}

test "getFirstAndLastDigit test" {
    var v = try getFirstAndLastDigit("a1bb3cc");
    try std.testing.expect(v.a == 1 and v.b == 3);

    v = try getFirstAndLastDigit("2bb4cc");
    try std.testing.expect(v.a == 2 and v.b == 4);

    v = try getFirstAndLastDigit("3bb5");
    try std.testing.expect(v.a == 3 and v.b == 5);

    v = try getFirstAndLastDigit("aa3bb5");
    try std.testing.expect(v.a == 3 and v.b == 5);

    v = try getFirstAndLastDigit("45");
    try std.testing.expect(v.a == 4 and v.b == 5);

    v = try getFirstAndLastDigit("485");
    try std.testing.expect(v.a == 4 and v.b == 5);

    v = try getFirstAndLastDigit("asd4asd8as34d5asd");
    try std.testing.expect(v.a == 4 and v.b == 5);

    v = try getFirstAndLastDigit("9vxfg");
    try std.testing.expect(v.a == 9 and v.b == 9);

    v = try getFirstAndLastDigit("asd4asasd");
    try std.testing.expect(v.a == 4 and v.b == 4);

    const v1 = getFirstAndLastDigit("asdasasd");
    try std.testing.expectError(NoDigitError.DigitNotFoundError, v1);
}
