const std = @import("std");

pub fn Stack(comptime Child : type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        gpa: std.mem.Allocator,
        top: ?*Node,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{
                .gpa = gpa,
                .top = null,
            };
        }

        pub fn push(this: *This, value: Child) !void {
            const node = try this.gpa.create(Node);
            node.* = .{ .data = value, .next = this.top};
            this.top = node;
        }

        pub fn pop(this: *This) !Child {
            const top = this.top orelse return error.EmptyStack;
            defer this.gpa.destroy(top);
            this.top = top.next;
            return top.data;
        }
    };
}

test "stack" {
    var stack = Stack(i32).init(std.testing.allocator);

    try std.testing.expectError(error.EmptyStack, stack.pop());

    try stack.push(25);
    try stack.push(50);
    try stack.push(75);
    try stack.push(100);

    try std.testing.expectEqual(stack.pop(), 100);
    try std.testing.expectEqual(stack.pop(), 75);
    try std.testing.expectEqual(stack.pop(), 50);
    try std.testing.expectEqual(stack.pop(), 25);
    try std.testing.expectError(error.EmptyStack, stack.pop());

    try stack.push(1);
    try std.testing.expectEqual(stack.pop(), 1);
    try std.testing.expectError(error.EmptyStack, stack.pop());
}
