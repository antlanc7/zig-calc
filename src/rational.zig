const std = @import("std");

pub fn Rational(comptime Underlying: type) type {
    if (@typeInfo(Underlying) != .Int or @typeInfo(Underlying).Int.signedness != .signed) {
        @compileError("Underlying type must be a signed integer");
    }

    return struct {
        num: Underlying,
        den: Underlying,
        const This = @This();

        pub fn init(num: Underlying, den: Underlying) This {
            std.debug.assert(den != 0);

            const r = This{ .num = num, .den = den };
            return r.simplify();
        }

        pub inline fn initFromInt(num: Underlying) This {
            return .{ .num = num, .den = 1 };
        }

        fn parseDecimalNumber(text: []const u8) !This {
            var tokens = std.mem.tokenizeScalar(u8, text, '.');
            const integerPart = tokens.next().?;
            var num = try std.fmt.parseInt(Underlying, integerPart, 10);
            var den: Underlying = 1;

            if (tokens.next()) |decimalPartToken| {
                const decimalPart = std.mem.trimRight(u8, decimalPartToken, "0");
                if (decimalPart.len != 0) {
                    den = try std.math.powi(Underlying, 10, @intCast(decimalPart.len));
                    num *= den;
                    num += std.math.sign(num) * try std.fmt.parseInt(Underlying, decimalPart, 10);
                }
            }

            return init(num, den);
        }

        pub fn parse(text: []const u8) !This {
            var tokens = std.mem.tokenizeScalar(u8, text, '/');

            const top = try parseDecimalNumber(tokens.next().?);

            if (tokens.next()) |bottomToken| {
                const bottom = try parseDecimalNumber(bottomToken);
                if (bottom.num == 0) return error.ZeroDenominator;
                return top.div(bottom);
            }

            return top;
        }

        pub fn simplify(this: *const This) This {
            const absNum = @abs(this.num);
            const absDen = @abs(this.den);
            const gcd = std.math.gcd(absNum, absDen);
            const sign: Underlying = if ((this.num >= 0) == (this.den > 0)) 1 else -1;
            return .{
                .num = sign * @as(Underlying, @intCast(absNum / gcd)),
                .den = @intCast(absDen / gcd),
            };
        }

        pub fn sum(this: *const This, other: This) This {
            return init(this.num * other.den + other.num * this.den, this.den * other.den);
        }

        pub fn sub(this: *const This, other: This) This {
            return init(this.num * other.den - other.num * this.den, this.den * other.den);
        }

        pub fn mul(this: *const This, other: This) This {
            return init(this.num * other.num, this.den * other.den);
        }

        pub fn div(this: *const This, other: This) This {
            return init(this.num * other.den, this.den * other.num);
        }

        pub fn toFloat(this: *const This, comptime T: type) T {
            return @as(T, @floatFromInt(this.num)) / @as(T, @floatFromInt(this.den));
        }

        pub fn format(value: This, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            if (value.den == 1) {
                try std.fmt.format(writer, "{d}", .{value.num});
            } else {
                try std.fmt.format(writer, "{d}/{d} = {d:.2}", .{ value.num, value.den, value.toFloat(f64) });
            }
        }
    };
}

test "rational numbers" {
    const RationalInt = Rational(i128);

    try std.testing.expectEqual(RationalInt.parse("0"), RationalInt{ .num = 0, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("0."), RationalInt{ .num = 0, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("0.0"), RationalInt{ .num = 0, .den = 1 });

    try std.testing.expectEqual(RationalInt.parse("-0"), RationalInt{ .num = 0, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("-0."), RationalInt{ .num = 0, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("-0.0"), RationalInt{ .num = 0, .den = 1 });

    try std.testing.expectEqual(RationalInt.parse("1"), RationalInt{ .num = 1, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("1."), RationalInt{ .num = 1, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("1.0"), RationalInt{ .num = 1, .den = 1 });

    try std.testing.expectEqual(RationalInt.parse("1.01"), RationalInt{ .num = 101, .den = 100 });

    try std.testing.expectEqual(RationalInt.parse("-3"), RationalInt{ .num = -3, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("-3."), RationalInt{ .num = -3, .den = 1 });
    try std.testing.expectEqual(RationalInt.parse("-3.0"), RationalInt{ .num = -3, .den = 1 });

    try std.testing.expectEqual(RationalInt.parse("1.1"), RationalInt{ .num = 11, .den = 10 });
    try std.testing.expectEqual(RationalInt.parse("2.2"), RationalInt{ .num = 11, .den = 5 });
    try std.testing.expectEqual(RationalInt.parse("-3.3"), RationalInt{ .num = -33, .den = 10 });

    try std.testing.expectEqual(RationalInt.parse("3.14"), RationalInt{ .num = 157, .den = 50 });

    try std.testing.expectEqual(RationalInt.parse("1.0000000000000000000000000000000000001"), RationalInt{ .num = 10000000000000000000000000000000000001, .den = 10000000000000000000000000000000000000 });
}

test "rational fractions" {
    const RationalInt = Rational(isize);
    try std.testing.expectEqual(RationalInt.parse("4/9"), RationalInt{ .num = 4, .den = 9 });
    try std.testing.expectEqual(RationalInt.parse("-7/5"), RationalInt{ .num = -7, .den = 5 });
}

test "rational fractions auto simplify" {
    const RationalInt = Rational(isize);
    try std.testing.expectEqual(RationalInt.parse("4/10"), RationalInt{ .num = 2, .den = 5 });
    try std.testing.expectEqual(RationalInt.parse("-7/14"), RationalInt{ .num = -1, .den = 2 });
    try std.testing.expectEqual(RationalInt.parse("1/-2"), RationalInt{ .num = -1, .den = 2 });
    try std.testing.expectEqual(RationalInt.parse("-1/-2"), RationalInt{ .num = 1, .den = 2 });
}

test "rationals sum" {
    const RationalInt = Rational(isize);
    try std.testing.expectEqual((try RationalInt.parse("1/2")).sum(try RationalInt.parse("1/3")), RationalInt{ .num = 5, .den = 6 });
    try std.testing.expectEqual((try RationalInt.parse("-1/3")).sum(try RationalInt.parse("1/2")), RationalInt{ .num = 1, .den = 6 });
}
