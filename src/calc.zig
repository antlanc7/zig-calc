const std = @import("std");
const Stack = @import("stack.zig").Stack;
const Rational = @import("rational.zig").Rational;

test "import_stack_library" {
    var my_stack = Stack(i32).init(std.testing.allocator);
    try std.testing.expectError(error.EmptyStack, my_stack.pop());
}

pub fn Calculator(comptime Number: type) type {
    return struct {
        const Self = @This();
        const isUnderlyingRational = @typeInfo(Number) == .Struct and @typeInfo(Number).Struct.fields.len == 2 and @typeInfo(@typeInfo(Number).Struct.fields[0].type) == .Int and @typeInfo(@typeInfo(Number).Struct.fields[1].type) == .Int;
        const zero = if (isUnderlyingRational) Number.initFromInt(0) else 0;
        const one = if (isUnderlyingRational) Number.initFromInt(1) else 1;
        stack: Stack(Number),
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .stack = Stack(Number).init(allocator) };
        }

        inline fn isOperation(char: u8) bool {
            return switch (char) {
                '+', '-', '*', '/' => true,
                else => false,
            };
        }

        inline fn defaultOperand(operation: u8) Number {
            return switch (operation) {
                '+', '-' => zero,
                '*', '/' => one,
                else => unreachable,
            };
        }

        pub fn eval(self: *Self, line: []const u8) !Number {
            var tokens = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
            while (tokens.next()) |tok| {
                if (tok.len == 1 and isOperation(tok[0])) {
                    const operator = tok[0];
                    const op2 = self.stack.pop() catch defaultOperand(operator);
                    const op1 = self.stack.pop() catch defaultOperand(operator);
                    const result = switch (operator) {
                        '+' => if (isUnderlyingRational) op1.sum(op2) else op1 + op2,
                        '-' => if (isUnderlyingRational) op1.sub(op2) else op1 - op2,
                        '*' => if (isUnderlyingRational) op1.mul(op2) else op1 * op2,
                        '/' => if (isUnderlyingRational) op1.div(op2) else switch (@typeInfo(Number)) {
                            .Float, .ComptimeFloat => op1 / op2,
                            else => @divTrunc(op1, op2),
                        },
                        else => unreachable,
                    };
                    try self.stack.push(result);
                } else {
                    const val: Number = if (isUnderlyingRational) try Number.parse(tok) else switch (@typeInfo(Number)) {
                        .Float, .ComptimeFloat => try std.fmt.parseFloat(Number, tok),
                        else => try std.fmt.parseInt(Number, tok, 10),
                    };
                    try self.stack.push(val);
                }
            }
            return self.stack.pop();
        }
    };
}

test "default operand" {
    var calculator = Calculator(i32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("+"), 0);
    try std.testing.expectEqual(calculator.eval("-"), 0);
    try std.testing.expectEqual(calculator.eval("*"), 1);
    try std.testing.expectEqual(calculator.eval("/"), 1);
    try std.testing.expectEqual(calculator.eval("+"), 0);
    try std.testing.expectEqual(calculator.eval("23 +"), 23);
    try std.testing.expectEqual(calculator.eval("4 /"), 0);
}

test "calculator int" {
    var calculator = Calculator(i32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23 7 -"), 16);
}

test "calculator float" {
    var calculator = Calculator(f32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23.5 7.7 +"), 31.2);
    try std.testing.expectEqual(calculator.eval("0.1 0.2 +"), calculator.eval("0.3"));
}

test "calculator double" {
    var calculator = Calculator(f64).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23.5 7.7 +"), 31.2);
}

test "calculator rational" {
    const RationalIsize = Rational(isize);
    var calculator = Calculator(RationalIsize).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), RationalIsize.initFromInt(30));
    try std.testing.expectEqual(calculator.eval("23.5 7.7 +"), RationalIsize.init(312, 10));
}
