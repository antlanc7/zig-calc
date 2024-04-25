const std = @import("std");
const Stack = @import("stack.zig").Stack;

test "import_stack_library" {
    var my_stack = Stack(i32).init(std.testing.allocator);
    try std.testing.expectError(error.EmptyStack, my_stack.pop());
}

pub fn Calculator(comptime Number: type) type {
    return struct {
        const Self = @This();
        stack: Stack(Number),
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .stack = Stack(Number).init(allocator) };
        }

        fn defaultOperand(operation: u8) !Number {
            return switch (operation) {
                '+', '-' => 0,
                '*', '/' => 1,
                else => error.InvalidOperation,
            };
        }

        pub fn eval(self: *Self, line: []const u8) !Number {
            var tokens = std.mem.tokenize(u8, line, &std.ascii.whitespace);
            while (tokens.next()) |tok| {
                if (tok.len == 1 and std.mem.indexOfScalar(u8, "+-*/", tok[0]) != null) {
                    const operator = tok[0];
                    const op2 = self.stack.pop() catch defaultOperand(operator) catch unreachable;
                    const op1 = self.stack.pop() catch defaultOperand(operator) catch unreachable;
                    const result = switch (operator) {
                        '+' => op1 + op2,
                        '-' => op1 - op2,
                        '*' => op1 * op2,
                        '/' => switch (@typeInfo(Number)) {
                            .Float, .ComptimeFloat => op1 / op2,
                            else => @divTrunc(op1, op2),
                        },
                        else => unreachable,
                    };
                    try self.stack.push(result);
                } else {
                    const val: Number = switch (@typeInfo(Number)) {
                        .Float, .ComptimeFloat => std.fmt.parseFloat(Number, tok) catch continue,
                        else => std.fmt.parseInt(Number, tok, 10) catch continue,
                    };
                    try self.stack.push(val);
                }
            }
            return self.stack.pop();
        }
    };
}

test "default_operand" {
    var calculator = Calculator(i32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("+"), 0);
    try std.testing.expectEqual(calculator.eval("-"), 0);
    try std.testing.expectEqual(calculator.eval("*"), 1);
    try std.testing.expectEqual(calculator.eval("/"), 1);
    try std.testing.expectEqual(calculator.eval("+"), 0);
    try std.testing.expectEqual(calculator.eval("23 +"), 23);
    try std.testing.expectEqual(calculator.eval("4 /"), 0);
}

test "calculator_int" {
    var calculator = Calculator(i32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23 7 -"), 16);
}

test "calculator_float" {
    var calculator = Calculator(f32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23.5 7.7 +"), 31.2);
}

test "calculator_double" {
    var calculator = Calculator(f64).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
    try std.testing.expectEqual(calculator.eval("23.5 7.7 +"), 31.2);
}
