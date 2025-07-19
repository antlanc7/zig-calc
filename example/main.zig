const std = @import("std");
const calc = @import("calc");
const print = std.debug.print;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();

    var dbgallocator = std.heap.DebugAllocator(.{}){};
    defer _ = dbgallocator.deinit();
    const allocator = dbgallocator.allocator();

    const calculator = calc.Calculator(calc.Rational(i64));

    while (true) {
        print("Enter the expression to evaluate: ", .{});
        const line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) orelse return error.EmptyStream;
        defer allocator.free(line);
        const strippedLine = std.mem.trimRight(u8, line, &std.ascii.whitespace);
        if (strippedLine.len == 0) continue;
        if (std.mem.startsWith(u8, strippedLine, "exit")) break;

        if (calculator.eval(allocator, strippedLine)) |result| {
            print("The result is {}\n", .{result});
        } else |_| {
            print("Invalid expression\n", .{});
        }
    }
}
