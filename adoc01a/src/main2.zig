const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = try readFile(allocator, "/Users/hvo/zig/adoc2023/adoc01a/data/a.txt");

    var sum: u64 = 0;
    for (lines, 1..) |line, idx| {
        // const digits: *const DigitPair = DigitPair.instance(line) catch &DigitPair.getAdditiveIdentity();
        const digits: *const DigitPair = DigitPair.instance(line) catch |err| switch (err) {
            error.DigitNotFoundError => &DigitPair.getAdditiveIdentity(),
            else => return err
        };
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

const DigitPairErrors = error{DigitNotFoundError, OtherError};

const DigitPair = struct {
    first_digit: u8,
    second_digit: u8,

    const text_number_tokens = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    const number_tokens = [_][]const u8{ "1", "2", "3", "4", "5", "6", "7", "8", "9" };
    const all_tokens = text_number_tokens ++ number_tokens;

    pub fn getNumber(self: *const @This()) u8 {
        return (self.first_digit * 10) + self.second_digit;
    }

    pub fn getFirstAndLastDigit(self: *@This(), s: []const u8) !*DigitPair {
        const allocator = std.heap.page_allocator;
        const numbers = try parseLine(allocator, s);
        if (numbers.len == 0) {
            try std.io.getStdErr().writer().print("No Digit in: {s}\n", .{s});
            return DigitPairErrors.DigitNotFoundError;
        }

        self.first_digit = numbers[0];
        self.second_digit = numbers[numbers.len - 1];
        return self;
    }

    pub fn instance(s: []const u8) !*DigitPair {
        var digits = DigitPair{ .first_digit = 0, .second_digit = 0 };
        return try digits.getFirstAndLastDigit(s);
    }

    fn tokenize(allocator: Allocator, s: []const u8) ![][]const u8 {
        var tknList = std.ArrayList([]const u8).init(allocator);
        var i: u64 = 0;
        while (i < s.len) : (i += 1) {
            for (all_tokens) |tkn| {
                const endIdx = i + tkn.len;
                if (endIdx <= s.len) {
                    if (std.mem.eql(u8, tkn, s[i..(endIdx)])) {
                        try tknList.append(tkn);
                    }
                }
            }
        }
        return tknList.toOwnedSlice();
    }

    fn token2int(allocator: Allocator, token_list: [][]const u8) ![]const u8 {
        var numbers = std.ArrayList(u8).init(allocator);
        for (token_list) |tkn| {
            for (all_tokens, 0..) |tkn_template, idx| {
                if (std.mem.eql(u8, tkn_template, tkn)) {
                    const n: u8 = @intCast((idx % number_tokens.len) + 1);
                    numbers.append(n) catch unreachable;
                }
            }
        }
        return numbers.toOwnedSlice();
    }

    fn parseLine(allocator: Allocator, s: []const u8) ![]const u8 {
        const step1 = try tokenize(allocator, s);
        defer allocator.free(step1);
        return token2int(allocator, step1);
    }

    fn getAdditiveIdentity() DigitPair {
        return DigitPair{ .first_digit = 0, .second_digit = 0 };
    }
};

test "tokenizer test" {
    const s = "aoneb3feightd";
    // Example to convert string literal to a mutable u8 slice - []u8.
    // var buf: [100]u8 = [_]u8{0} ** 100;
    // const s1 = try std.fmt.bufPrint(&buf, "{s}", .{s});
    const token_list = try DigitPair.tokenize(std.testing.allocator, s);
    defer std.testing.allocator.free(token_list);
    try expectEqual(3, token_list.len);
    try expect(std.mem.eql(u8, "3", token_list[1]));
    try expect(std.mem.eql(u8, "eight", token_list[2]));

    const numbers = try DigitPair.token2int(std.testing.allocator, token_list);
    defer std.testing.allocator.free(numbers);
    try expectEqual(3, numbers.len);
    try expectEqual(1, numbers[0]);
    try expectEqual(3, numbers[1]);
    try expectEqual(8, numbers[2]);

    const numbers2 = try DigitPair.parseLine(std.testing.allocator, s);
    defer std.testing.allocator.free(numbers2);
    try expectEqual(3, numbers2.len);
    try expectEqual(1, numbers2[0]);
    try expectEqual(3, numbers2[1]);
    try expectEqual(8, numbers2[2]);

    const numbers3 = try DigitPair.parseLine(std.testing.allocator, "abcd");
    defer std.testing.allocator.free(numbers3);
    try expectEqual(0, numbers3.len);

    const numbers4 = try DigitPair.parseLine(std.testing.allocator, "");
    defer std.testing.allocator.free(numbers4);
    try expectEqual(0, numbers4.len);

    const numbers5 = try DigitPair.parseLine(std.testing.allocator, "7");
    defer std.testing.allocator.free(numbers5);
    try expectEqual(1, numbers5.len);
    try expectEqual(7, numbers5[0]);

    const numbers6 = try DigitPair.parseLine(std.testing.allocator, "seven");
    defer std.testing.allocator.free(numbers6);
    try expectEqual(1, numbers6.len);
    try expectEqual(7, numbers6[0]);
}

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

    v1 = try v1.getFirstAndLastDigit("two4dddpmrhh7fourthreeeight9");
    try std.testing.expect(v1.first_digit == 2 and v1.second_digit == 9);

    const v2 = v1.getFirstAndLastDigit("asdasasd");
    try std.testing.expectError(DigitPairErrors.DigitNotFoundError, v2);
}
