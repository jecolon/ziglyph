const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Element = struct {
    l1: u16,
    l2: u16,
    l3: u16,
};

pub const Elements = [18]?Element;
pub const Key = [3]?u21;
const NodeMap = std.AutoHashMap(u21, Node);

const Node = struct {
    value: ?Elements,
    children: ?NodeMap,

    fn init() Node {
        return Node{
            .value = null,
            .children = null,
        };
    }

    fn deinit(self: *Node) void {
        if (self.children) |*children| {
            var iter = children.iterator();
            while (iter.next()) |entry| {
                entry.value_ptr.deinit();
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
root: Node,

const Self = @This();

pub fn init(allocator: *mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        .root = Node.init(),
    };
}

pub fn deinit(self: *Self) void {
    self.root.deinit();
}

pub fn add(self: *Self, key: Key, value: Elements) !void {
    var current_node = &self.root;

    for (key) |maybe_cp| {
        if (maybe_cp) |cp| {
            if (current_node.children == null) current_node.children = NodeMap.init(self.allocator);
            var result = try current_node.children.?.getOrPut(cp);
            if (!result.found_existing) {
                result.value_ptr.* = Node.init();
            }
            current_node = result.value_ptr;
        } else {
            break;
        }
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

    return .{ .index = success_index, .value = success_value };
}

test "Collator Trie" {
    var trie = init(std.testing.allocator);
    defer trie.deinit();

    var a1 = [_]?Element{null} ** 18;
    a1[0] = .{ .l1 = 1, .l2 = 1, .l3 = 1 };
    a1[1] = .{ .l1 = 2, .l2 = 2, .l3 = 2 };
    var a2 = [_]?Element{null} ** 18;
    a2[0] = .{ .l1 = 1, .l2 = 1, .l3 = 1 };
    a2[1] = .{ .l1 = 2, .l2 = 2, .l3 = 2 };
    a2[2] = .{ .l1 = 3, .l2 = 3, .l3 = 3 };

    try trie.add([_]?u21{ 1, 2, null }, a1);
    try trie.add([_]?u21{ 1, 2, 3 }, a2);

    var lookup = trie.find(&[_]u21{ 1, 2 });
    try testing.expectEqual(@as(usize, 1), lookup.index);
    try testing.expectEqualSlices(?Element, &a1, &lookup.value.?);
    lookup = trie.find(&[_]u21{ 1, 2, 3 });
    try testing.expectEqual(@as(usize, 2), lookup.index);
    try testing.expectEqualSlices(?Element, &a2, &lookup.value.?);
    lookup = trie.find(&[_]u21{1});
    try testing.expectEqual(@as(usize, 0), lookup.index);
    try testing.expect(lookup.value == null);
}
