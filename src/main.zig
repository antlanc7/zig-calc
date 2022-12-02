const std = @import("std");
const Calculator = @import("calc.zig").Calculator;
const print = std.debug.print;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var calculator = Calculator(f32).init(allocator);

    print("Enter the expression to evaluate:", .{});
    const line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) orelse return error.EmptyStream;
    print("{s}", .{line});

    const result = try calculator.eval(line);
    print("The result is {d}", .{result});
}
