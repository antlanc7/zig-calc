const std = @import("std");

pub fn Stack(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        top: ?*Node = null,

        pub fn push(this: *This, allocator: std.mem.Allocator, value: Child) !void {
            const node = try allocator.create(Node);
            node.* = .{ .data = value, .next = this.top };
            this.top = node;
        }

        pub fn pop(this: *This, allocator: std.mem.Allocator) !Child {
            const top = this.top orelse return error.EmptyStack;
            defer allocator.destroy(top);
            this.top = top.next;
            return top.data;
        }

        pub fn deinit(this: *This, allocator: std.mem.Allocator) void {
            var node = this.top;
            while (node) |n| {
                node = n.next;
                allocator.destroy(n);
            }
        }
    };
}

test "stack" {
    var stack = Stack(i32){};
    const alloc = std.testing.allocator;

    try std.testing.expectError(error.EmptyStack, stack.pop(alloc));

    try stack.push(alloc, 25);
    try stack.push(alloc, 50);
    try stack.push(alloc, 75);
    try stack.push(alloc, 100);

    try std.testing.expectEqual(stack.pop(alloc), 100);
    try std.testing.expectEqual(stack.pop(alloc), 75);
    try std.testing.expectEqual(stack.pop(alloc), 50);
    try std.testing.expectEqual(stack.pop(alloc), 25);
    try std.testing.expectError(error.EmptyStack, stack.pop(alloc));

    try stack.push(alloc, 1);
    try std.testing.expectEqual(stack.pop(alloc), 1);
    try std.testing.expectError(error.EmptyStack, stack.pop(alloc));
}
