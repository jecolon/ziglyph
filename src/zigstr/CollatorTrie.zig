const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Element = struct {
    l1: u16,
    l2: u16,
    l3: u16,
};

pub const Elements = [18]?Element;
const NodeMap = std.AutoHashMap(u21, *Node);

const Node = struct {
    allocator: *mem.Allocator,
    value: ?Elements,
    children: ?NodeMap,

    fn init(allocator: *mem.Allocator) Node {
        return Node{
            .allocator = allocator,
            .value = null,
            .children = null,
        };
    }

    fn deinit(self: *Node) void {
        if (self.children) |*children| {
            var iter = children.iterator();
            while (iter.next()) |entry| {
                entry.value.deinit();
                self.allocator.destroy(entry.value);
            }
            children.deinit();
        }
    }
};

pub const Lookup = struct {
    index: usize,
    value: ?Elements,
};

allocator: *mem.Allocator,
root: *Node,

const Self = @This();

pub fn init(allocator: *mem.Allocator) !Self {
    var root = try allocator.create(Node);
    root.* = Node.init(allocator);

    return Self{
        .allocator = allocator,
        .root = root,
    };
}

pub fn deinit(self: *Self) void {
    self.root.deinit();
    self.allocator.destroy(self.root);
}

pub fn add(self: *Self, key: []const u21, value: Elements) !void {
    var current_node = self.root;

    //if (key[0] == 0x0344) {
    //    for (value) |element| {
    //        if (element) |e| std.debug.print("add {x} {x} {x}\n", .{ e.l1, e.l2, e.l3 });
    //    }
    //}

    for (key) |cp| {
        if (current_node.children == null) current_node.children = NodeMap.init(self.allocator);
        var result = try current_node.children.?.getOrPut(cp);
        if (!result.found_existing) {
            var node = try self.allocator.create(Node);
            node.* = Node.init(self.allocator);
            result.entry.value = node;
        }
        current_node = result.entry.value;
    }

    current_node.value = value;
}

pub fn find(self: Self, key: []const u21) Lookup {
    var current_node = self.root;
    var success_index: usize = 0;
    var success_value: ?Elements = null;

    for (key) |cp, i| {
        if (current_node.children == null or current_node.children.?.get(cp) == null) break;

        current_node = current_node.children.?.get(cp).?;

        if (current_node.value) |value| {
            success_index = i;
            success_value = value;
        }
    }

    if (key[0] == 0x0344) {
        for (success_value.?) |element| {
            if (element) |e| std.debug.print("find {x} {x} {x}\n", .{ e.l1, e.l2, e.l3 });
        }
    }

    return .{ .index = success_index, .value = success_value };
}

test "Collator Trie" {
    var trie = try init(std.testing.allocator);
    defer trie.deinit();

    var a1 = [_]?Element{null} ** 18;
    a1[0] = .{ .l1 = 1, .l2 = 1, .l3 = 1 };
    a1[1] = .{ .l1 = 2, .l2 = 2, .l3 = 2 };
    var a2 = [_]?Element{null} ** 18;
    a2[0] = .{ .l1 = 1, .l2 = 1, .l3 = 1 };
    a2[1] = .{ .l1 = 2, .l2 = 2, .l3 = 2 };
    a2[2] = .{ .l1 = 3, .l2 = 3, .l3 = 3 };

    try trie.add(&[_]u21{ 1, 2 }, a1);
    try trie.add(&[_]u21{ 1, 2, 3 }, a2);

    var lookup = trie.find(&[_]u21{ 1, 2 });
    testing.expectEqual(@as(usize, 1), lookup.index);
    testing.expectEqualSlices(?Element, &a1, &lookup.value.?);
    lookup = trie.find(&[_]u21{ 1, 2, 3 });
    testing.expectEqual(@as(usize, 2), lookup.index);
    testing.expectEqualSlices(?Element, &a2, &lookup.value.?);
    lookup = trie.find(&[_]u21{1});
    testing.expectEqual(@as(usize, 0), lookup.index);
    testing.expect(lookup.value == null);
}
