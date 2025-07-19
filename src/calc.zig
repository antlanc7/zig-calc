const std = @import("std");
const Stack = @import("stack.zig").Stack;
const Rational = @import("rational.zig").Rational;

test "import_stack_library" {
    var my_stack = Stack(i32){};
    try std.testing.expectError(error.EmptyStack, my_stack.pop(std.testing.allocator));
}

pub fn Calculator(comptime Number: type) type {
    return struct {
        const Self = @This();
        const isUnderlyingRational = @typeInfo(Number) == .@"struct" and @typeInfo(Number).@"struct".fields.len == 2 and @typeInfo(@typeInfo(Number).@"struct".fields[0].type) == .int and @typeInfo(@typeInfo(Number).@"struct".fields[1].type) == .int;
        const zero = if (isUnderlyingRational) Number.initFromInt(0) else 0;
        const one = if (isUnderlyingRational) Number.initFromInt(1) else 1;

        fn isOperation(char: u8) bool {
            return switch (char) {
                '+', '-', '*', '/' => true,
                else => false,
            };
        }

        fn defaultOperand(operation: u8) Number {
            return switch (operation) {
                '+', '-' => zero,
                '*', '/' => one,
                else => unreachable,
            };
        }

        /// evaluate an expression
        ///
        /// it takes an allocator but it always frees everything it allocates before returning
        pub fn eval(allocator: std.mem.Allocator, line: []const u8) !Number {
            var stack: Stack(Number) = .{};
            errdefer stack.deinit(allocator);
            var tokens = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
            while (tokens.next()) |tok| {
                if (tok.len == 1 and isOperation(tok[0])) {
                    const operator = tok[0];
                    const op2 = stack.pop(allocator) catch defaultOperand(operator);
                    const op1 = stack.pop(allocator) catch defaultOperand(operator);
                    const result = switch (operator) {
                        '+' => if (isUnderlyingRational) op1.sum(op2) else op1 + op2,
                        '-' => if (isUnderlyingRational) op1.sub(op2) else op1 - op2,
                        '*' => if (isUnderlyingRational) op1.mul(op2) else op1 * op2,
                        '/' => if (isUnderlyingRational) op1.div(op2) else switch (@typeInfo(Number)) {
                            .float, .comptime_float => op1 / op2,
                            else => @divTrunc(op1, op2),
                        },
                        else => unreachable,
                    };
                    try stack.push(allocator, result);
                } else {
                    const val: Number = if (isUnderlyingRational) try Number.parse(tok) else switch (@typeInfo(Number)) {
                        .float, .comptime_float => try std.fmt.parseFloat(Number, tok),
                        else => try std.fmt.parseInt(Number, tok, 10),
                    };
                    try stack.push(allocator, val);
                }
            }
            return stack.pop(allocator);
        }
    };
}

test "default operand" {
    const allocator = std.testing.allocator;
    const calculator = Calculator(i32);
    try std.testing.expectEqual(calculator.eval(allocator, "+"), 0);
    try std.testing.expectEqual(calculator.eval(allocator, "-"), 0);
    try std.testing.expectEqual(calculator.eval(allocator, "*"), 1);
    try std.testing.expectEqual(calculator.eval(allocator, "/"), 1);
    try std.testing.expectEqual(calculator.eval(allocator, "+"), 0);
    try std.testing.expectEqual(calculator.eval(allocator, "23 +"), 23);
    try std.testing.expectEqual(calculator.eval(allocator, "4 /"), 0);
}

test "calculator int" {
    const allocator = std.testing.allocator;
    const calculator = Calculator(i32);
    try std.testing.expectEqual(calculator.eval(allocator, "23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval(allocator, "23 7 -"), 16);
}

test "calculator float" {
    const allocator = std.testing.allocator;
    const calculator = Calculator(f32);
    try std.testing.expectEqual(calculator.eval(allocator, "23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval(allocator, "23.5 7.7 +"), 31.2);
    try std.testing.expectEqual(calculator.eval(allocator, "0.1 0.2 +"), calculator.eval(allocator, "0.3"));
}

test "calculator double" {
    const allocator = std.testing.allocator;
    const calculator = Calculator(f64);
    try std.testing.expectEqual(calculator.eval(allocator, "23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval(allocator, "23.5 7.7 +"), 31.2);
}

test "calculator rational" {
    const allocator = std.testing.allocator;
    const RationalIsize = Rational(isize);
    const calculator = Calculator(RationalIsize);
    try std.testing.expectEqual(calculator.eval(allocator, "23 7 +"), RationalIsize.initFromInt(30));
    try std.testing.expectEqual(calculator.eval(allocator, "23.5 7.7 +"), RationalIsize.init(312, 10));
}
