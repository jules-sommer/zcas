const std = @import("std");
const testing = std.testing;

/// Up to 6 digits (XXXXXX)
a: u24,

/// Two digits (YY)
b: u7,

/// Single digit (Z)
check: u4,

const CasNumber = @This();

/// A type that allows you to represent a CAS number as a tuple of .{ u24, u7, u4 }
pub const Tuple = struct { u24, u7, u4 };

pub fn fromTuple(cas_number: Tuple) CasNumber {
    const a, const b, const check = cas_number;
    return .{
        .a = a,
        .b = b,
        .check = check,
    };
}
pub fn asTuple(self: *CasNumber) Tuple {
    return .{
        self.a,
        self.b,
        self.check,
    };
}

const DesiredOutType = enum {
    tuple,
    @"struct",
};

fn ParseOutput(comptime desired_type: DesiredOutType) type {
    return switch (desired_type) {
        .tuple => Tuple,
        .@"struct" => CasNumber,
    };
}

pub const ParseError = error{
    InvalidFormat,
    InvalidCheckDigit,
};

/// Parses a CAS Registry number into either a tuple type, which is also provided, or a CasNumber struct,
/// the tuple type is largely used in function args to allow syntax like: `fn (.{ 1234, 12, 1 })`.
pub fn parseFromString(
    comptime output: DesiredOutType,
    cas: []const u8,
) (std.fmt.ParseIntError || ParseError)!ParseOutput(output) {
    if (std.mem.indexOfScalar(u8, cas, '-')) |idx1| {
        if (std.mem.lastIndexOfScalar(u8, cas, '-')) |idx2| {
            if (idx1 < 2 or idx1 > 7) return error.InvalidFormat;
            if (idx2 - idx1 < 2) return error.InvalidFormat;
        } else return error.InvalidFormat;
    } else return error.InvalidFormat;

    var split = std.mem.splitScalar(
        u8,
        std.mem.trim(u8, cas, " \t\n\r"),
        '-',
    );

    switch (output) {
        .tuple => return .{
            try std.fmt.parseInt(u24, split.next().?, 10),
            try std.fmt.parseInt(u7, split.next().?, 10),
            try std.fmt.parseInt(u4, split.next().?, 10),
        },
        .@"struct" => return .{
            .a = try std.fmt.parseInt(u24, split.next().?, 10),
            .b = try std.fmt.parseInt(u7, split.next().?, 10),
            .check = try std.fmt.parseInt(u4, split.next().?, 10),
        },
    }
}

fn testCasStringParse(string: []const u8, expected: Tuple) !void {
    try testing.expectEqual(expected, try CasNumber.parseFromString(.tuple, string));
}
fn testCasStringParseExpectError(string: []const u8, expected_error: anyerror) !void {
    try testing.expectError(expected_error, CasNumber.parseFromString(.tuple, string));
}

test parseFromString {
    try testCasStringParse("7732-18-5", .{ 7732, 18, 5 });
    try testCasStringParse("9999-99-9", .{ 9999, 99, 9 });
    try testCasStringParse("99999-99-9", .{ 99999, 99, 9 });
    try testCasStringParse("9999999-99-9", .{ 9999999, 99, 9 });
    try testCasStringParseExpectError("99999999-99-9", error.InvalidFormat);
    try testCasStringParseExpectError("9-99-9", error.InvalidFormat);
}

pub fn fromString(cas: []const u8) !CasNumber {
    return fromTuple(try parseFromString(.tuple, cas));
}

/// Validates the CAS number by confirming the check digit (third segment) matches the calculated check digit.
pub fn isValid(self: CasNumber) bool {
    return self.calculateCheckDigit() == self.check;
}

/// Calculates the CAS number check digit based on the `a` and `b` segments.
pub fn calculateCheckDigit(self: CasNumber) u8 {
    var sum: u32 = 0;
    var multiplier: u32 = 1;

    const b1 = self.b % 10;
    sum += b1 * multiplier;
    multiplier += 1;

    const b2 = self.b / 10;
    sum += b2 * multiplier;
    multiplier += 1;

    var a_segment = self.a;
    while (a_segment > 0) {
        const digit = a_segment % 10;
        sum += digit * multiplier;
        multiplier += 1;
        a_segment /= 10;
    }

    return @intCast(sum % 10);
}

test calculateCheckDigit {
    const water = CasNumber{
        .a = 7732,
        .b = 18,
        .check = 5,
    };
    const check = water.calculateCheckDigit();
    try std.testing.expectEqual(5, check);
}

/// Formats a CAS number in "XXXXXX-YY-Z" format.
pub fn format(
    self: CasNumber,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("Cas({d:_>7}-{d:0>2}-{d} | .valid: {})", .{ self.a, self.b, self.check, self.isValid() });
}
