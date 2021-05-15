const std = @import("std");
const mem = std.mem;
const testing = std.testing;

/// Decomposed is the result of a code point full decomposition. It can be one of:
/// * .src: Sorce code point.
/// * .same : Default canonical decomposition to the code point itself.
/// * .single : Singleton canonical decomposition to a different single code point.
/// * .canon : Canonical decomposition, which always results in two code points.
/// * .compat : Compatibility decomposition, which can results in at most 18 code points.
pub const Decomposed = union(enum) {
    src: u21,
    same: u21,
    single: u21,
    canon: [2]u21,
    compat: []const u21,
};

const NodeMap = std.AutoHashMap(u21, *Node);

const Node = struct {
    allocator: *mem.Allocator,
    value: ?Decomposed,
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
    value: ?Decomposed,
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

pub fn add(self: *Self, key: []const u8, value: Decomposed) !void {
    var current_node = self.root;

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

pub fn find(self: Self, key: []const u8) Lookup {
    var current_node = self.root;
    var success_index: usize = 0;
    var success_value: ?Decomposed = null;

    for (key) |byte, i| {
        if (current_node.children == null or current_node.children.?.get(byte) == null) break;

        current_node = current_node.children.?.get(byte).?;

        if (current_node.value) |value| {
            success_index = i;
            success_value = value;
        }
    }

    return .{ .index = success_index, .value = success_value };
}

test "DecompTrie" {
    var trie = try init(std.testing.allocator);
    defer trie.deinit();

    var d1 = Decomposed{ .same = 1 };
    var d2 = Decomposed{ .same = 2 };
    var d3 = Decomposed{ .same = 3 };
    var d4 = Decomposed{ .same = 4 };

    try trie.add(&[_]u8{1}, d1);
    try trie.add(&[_]u8{ 1, 2 }, d2);
    try trie.add(&[_]u8{ 1, 2, 3 }, d3);
    try trie.add(&[_]u8{ 1, 2, 3, 4 }, d4);

    var lookup = trie.find(&[_]u8{1});
    testing.expectEqual(@as(usize, 0), lookup.index);
    testing.expectEqual(d1, lookup.value.?);

    lookup = trie.find(&[_]u8{ 1, 2 });
    testing.expectEqual(@as(usize, 1), lookup.index);
    testing.expectEqual(d2, lookup.value.?);

    lookup = trie.find(&[_]u8{ 1, 2, 3 });
    testing.expectEqual(@as(usize, 2), lookup.index);
    testing.expectEqual(d3, lookup.value.?);

    lookup = trie.find(&[_]u8{ 1, 2, 3, 4 });
    testing.expectEqual(@as(usize, 3), lookup.index);
    testing.expectEqual(d4, lookup.value.?);
}
