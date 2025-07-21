const std = @import("std");
const calc = @import("calc");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stderr = std.io.getStdErr().writer();
    const stdout = std.io.getStdOut().writer();

    var dbgallocator = std.heap.DebugAllocator(.{}){};
    defer _ = dbgallocator.deinit();
    const allocator = dbgallocator.allocator();

    const calculator = calc.Calculator(calc.Rational(i64));

    while (true) {
        try stderr.print("Enter the expression to evaluate: ", .{});
        const line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) orelse return;
        defer allocator.free(line);
        const strippedLine = std.mem.trimRight(u8, line, &std.ascii.whitespace);
        if (strippedLine.len == 0) continue;
        if (std.mem.startsWith(u8, strippedLine, "exit")) break;

        if (calculator.eval(allocator, strippedLine)) |result| {
            try stderr.print("The result is ", .{});
            try stdout.print("{}", .{result});
            try stderr.writeByte('\n');
        } else |_| {
            try stderr.print("Invalid expression\n", .{});
        }
    }
}
