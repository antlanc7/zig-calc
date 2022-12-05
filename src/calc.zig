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

        pub fn eval(self: *Self, line: []const u8) !Number {
            var tokens = std.mem.tokenize(u8, line, &std.ascii.whitespace);
            while (tokens.next()) |tok| {
                if (tok.len == 1 and std.mem.indexOfScalar(u8, "+-*/", tok[0]) != null) {
                    const op2 = try self.stack.pop();
                    const op1 = try self.stack.pop();
                    const result = switch (tok[0]) {
                        '+' => op1 + op2,
                        '-' => op1 - op2,
                        '*' => op1 * op2,
                        '/' => if (comptime std.meta.trait.isSignedInt(Number)) @divTrunc(op1, op2) else op1 / op2,
                        else => unreachable,
                    };
                    try self.stack.push(result);
                } else {
                    var val: Number = undefined;
                    if (comptime std.meta.trait.isFloat(Number)) {
                        val = std.fmt.parseFloat(Number, tok) catch continue;
                    } else {
                        val = std.fmt.parseInt(Number, tok) catch continue;
                    }
                    try self.stack.push(val);
                }
            }
            return self.stack.pop();
        }
    };
}

test "calculator_int" {
    var calculator = Calculator(i32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
}

test "calculator_float" {
    var calculator = Calculator(f32).init(std.testing.allocator);
    try std.testing.expectEqual(calculator.eval("23 7 +"), 30);
}
