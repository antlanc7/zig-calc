const std = @import("std");
const Stack = @import("stack.zig").Stack;

test "import_stack_library" {
    var my_stack = Stack(i32).init(std.testing.allocator);
    try std.testing.expectError(error.EmptyStack, my_stack.pop());
}

pub fn Calculator(comptime Number: type) type {
    return struct {
        const This = @This();
        stack: Stack(Number),
        pub fn init(allocator: std.mem.Allocator) This {
            return This{ .stack = Stack(Number).init(allocator) };
        }

        pub fn eval(this: *This, line: []const u8) !Number {
            var curr_num: Number = 0;
            var parsing = false;

            for (line) |char| {
                if (char >= '0' and char <= '9') {
                    const val: Number = if (comptime std.meta.trait.isFloat(Number)) @intToFloat(Number, char - '0') else (char - '0');
                    if (parsing) {
                        curr_num = curr_num * 10 + val;
                    } else {
                        parsing = true;
                        curr_num = val;
                    }
                } else {
                    if (parsing) {
                        parsing = false;
                        try this.stack.push(curr_num);
                    }

                    if (std.mem.indexOfScalar(u8, "+-*/", char)) |_| {
                        const op2 = try this.stack.pop();
                        const op1 = try this.stack.pop();
                        const result = switch (char) {
                            '+' => op1 + op2,
                            '-' => op1 - op2,
                            '*' => op1 * op2,
                            '/' => if (comptime std.meta.trait.isSignedInt(Number)) @divTrunc(op1, op2) else op1 / op2,
                            else => unreachable,
                        };
                        try this.stack.push(result);
                    }
                }
            }
            return this.stack.pop();
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
