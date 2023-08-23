//! `Sentence` represents a sentence within a UTF-8 encoded string.

const std = @import("std");
const unicode = std.unicode;

const sbp = @import("../autogen/sentence_break_property.zig");
const CodePoint = @import("CodePoint.zig");
const CodePointIterator = CodePoint.CodePointIterator;

pub const Sentence = @This();

bytes: []const u8,
offset: usize,

/// `eql` compares `str` with the bytes of this sentence for equality.
pub fn eql(self: Sentence, str: []const u8) bool {
    return std.mem.eql(u8, self.bytes, str);
}

const Type = enum {
    aterm,
    close,
    cr,
    extend,
    format,
    lf,
    lower,
    numeric,
    oletter,
    scontinue,
    sep,
    sp,
    sterm,
    upper,
    any,

    fn get(cp: CodePoint) Type {
        var ty: Type = .any;
        if (0x000D == cp.code) ty = .cr;
        if (0x000A == cp.code) ty = .lf;
        if (sbp.isLower(cp.code)) ty = .lower;
        if (sbp.isUpper(cp.code)) ty = .upper;
        if (sbp.isOletter(cp.code)) ty = .oletter;
        if (sbp.isNumeric(cp.code)) ty = .numeric;
        if (sbp.isSep(cp.code)) ty = .sep;
        if (sbp.isSp(cp.code)) ty = .sp;
        if (sbp.isClose(cp.code)) ty = .close;
        if (sbp.isAterm(cp.code)) ty = .aterm;
        if (sbp.isSterm(cp.code)) ty = .sterm;
        if (sbp.isScontinue(cp.code)) ty = .scontinue;
        if (sbp.isExtend(cp.code)) ty = .extend;
        if (sbp.isFormat(cp.code)) ty = .format;

        return ty;
    }
};

const Token = struct {
    ty: Type,
    code_point: CodePoint,
    offset: usize = 0,

    fn is(self: Token, ty: Type) bool {
        return self.ty == ty;
    }
};

const TokenList = std.ArrayList(Token);

/// `SentenceIterator` iterates a string one sentence at-a-time.
pub const SentenceIterator = struct {
    bytes: []const u8,
    i: ?usize = null,
    start: ?Token = null,
    tokens: TokenList,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, str: []const u8) !Self {
        if (!unicode.utf8ValidateSlice(str)) return error.InvalidUtf8;

        var self = Self{
            .bytes = str,
            .tokens = TokenList.init(allocator),
        };

        try self.lex();

        if (self.tokens.items.len == 0) return error.NoTokens;
        self.start = self.tokens.items[0];

        // Set token offsets.
        for (self.tokens.items, 0..) |*token, i| {
            token.offset = i;
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
    }

    fn lex(self: *Self) !void {
        var iter = CodePointIterator{
            .bytes = self.bytes,
            .i = 0,
        };

        while (iter.next()) |cp| {
            try self.tokens.append(.{
                .ty = Type.get(cp),
                .code_point = cp,
            });
        }
    }

    // Main API.
    pub fn next(self: *Self) ?Sentence {
        no_break: while (self.advance()) |current_token| {
            if (isParaSep(current_token)) {
                var end = current_token;

                if (current_token.is(.cr)) {
                    if (self.peek()) |p| {
                        if (p.is(.lf)) {
                            _ = self.advance();
                            end = self.current();
                        }
                    }
                }

                const start = self.start.?;
                self.start = self.peek();

                return self.emit(start, end);
            }

            if (current_token.is(.aterm)) {
                var end = self.current();

                if (self.peek()) |p| {
                    if (isUpper(p)) {
                        // self.i may not be the same as current token's offset due to ignorable skipping.
                        const original_i = self.i;
                        self.i = current_token.offset;
                        defer self.i = original_i;

                        if (self.prevAfterSkip(isIgnorable)) |v| {
                            if (isUpperLower(v)) continue :no_break;
                        }
                    } else if (isParaSep(p) or isLower(p) or isNumeric(p) or isSContinue(p)) {
                        continue :no_break;
                    } else if (isSpace(p)) {
                        // ATerm Sp*
                        self.run(isSpace);
                        end = self.current();
                        // Possible lower case after.
                        if (self.peek()) |pp| {
                            if (isLower(pp)) continue :no_break;
                        }
                    } else if (isClose(p)) {
                        // ATerm Close*
                        self.run(isClose);
                        if (self.peek()) |pp| {
                            // Possible ParaSep after.
                            if (isParaSep(pp)) {
                                _ = self.advance();
                                end = self.current();
                                const start = self.start.?;
                                self.start = self.peek();

                                return self.emit(start, end);
                            }
                            // Possible spaces after.
                            if (isSpace(pp)) {
                                // ATerm Close* Sp*
                                self.run(isSpace);

                                if (self.peek()) |ppp| {
                                    // Possible lower after.
                                    if (isLower(ppp)) continue :no_break;
                                    // Possible lower after some allowed code points.
                                    if (isAllowedBeforeLower(ppp)) {
                                        if (self.peekAfterSkip(isAllowedBeforeLower)) |pppp| {
                                            // ATerm Close* Sp* !(Unallowed) Lower
                                            if (isLower(pppp)) continue :no_break;
                                        }
                                    }
                                }
                            }
                        }

                        end = self.current();
                    } else if (isSATerm(p)) {
                        self.run(isSATerm);
                        end = self.current();
                    }
                }

                const start = self.start.?;
                self.start = self.peek();

                return self.emit(start, end);
            }

            if (current_token.is(.sterm)) {
                var end = self.current();

                if (self.peek()) |p| {
                    if (isParaSep(p) or isSATerm(p) or isSContinue(p)) {
                        _ = self.advance();
                        end = self.current();
                    } else if (isSpace(p)) {
                        self.run(isSpace);
                        end = self.current();
                    } else if (isClose(p)) {
                        // STerm Close*
                        self.run(isClose);
                        if (self.peek()) |pp| {
                            if (isSpace(pp)) {
                                // STerm Close* Sp*
                                self.run(isSpace);
                            }
                        }

                        end = self.current();
                    }
                }

                const start = self.start.?;
                self.start = self.peek();

                return self.emit(start, end);
            }
        }

        return if (self.start) |start| self.emit(start, self.last()) else null;
    }

    // Token array movement.
    fn forward(self: *Self) bool {
        if (self.i) |*index| {
            index.* += 1;
            if (index.* >= self.tokens.items.len) return false;
        } else {
            self.i = 0;
        }

        return true;
    }

    // Token array movement.
    fn getRelative(self: Self, n: isize) ?Token {
        var index: usize = self.i orelse 0;

        if (n < 0) {
            if (index == 0 or -%n > index) return null;
            index -= @intCast(-%n);
        } else {
            const un: usize = @intCast(n);
            if (index + un >= self.tokens.items.len) return null;
            index += un;
        }

        return self.tokens.items[index];
    }

    fn prevAfterSkip(self: *Self, predicate: TokenPredicate) ?Token {
        if (self.i == null or self.i.? == 0) return null;

        var i: isize = 1;
        while (self.getRelative(-i)) |token| : (i += 1) {
            if (!predicate(token)) return token;
        }

        return null;
    }

    fn current(self: Self) Token {
        // Assumes self.i is not null.
        return self.tokens.items[self.i.?];
    }

    fn last(self: Self) Token {
        return self.tokens.items[self.tokens.items.len - 1];
    }

    fn peek(self: Self) ?Token {
        return self.getRelative(1);
    }

    fn peekAfterSkip(self: *Self, predicate: TokenPredicate) ?Token {
        var i: isize = 1;
        while (self.getRelative(i)) |token| : (i += 1) {
            if (!predicate(token)) return token;
        }

        return null;
    }

    fn advance(self: *Self) ?Token {
        const token = if (self.forward()) self.current() else return null;
        if (!isParaSep(token)) _ = self.skipIgnorables(token);

        return token;
    }

    fn run(self: *Self, predicate: TokenPredicate) void {
        while (self.peek()) |token| {
            if (!predicate(token)) break;
            _ = self.advance();
        }
    }

    fn skipIgnorables(self: *Self, end: Token) Token {
        if (self.peek()) |p| {
            if (isIgnorable(p)) {
                self.run(isIgnorable);
                return self.current();
            }
        }

        return end;
    }

    // Production.
    fn emit(self: Self, start_token: Token, end_token: Token) Sentence {
        const start = start_token.code_point.offset;
        const end = end_token.code_point.offset + end_token.code_point.len;

        return .{
            .bytes = self.bytes[start..end],
            .offset = start,
        };
    }
};

// Predicates
const TokenPredicate = *const fn (Token) bool;

fn isNumeric(token: Token) bool {
    return token.ty == .numeric;
}

fn isLower(token: Token) bool {
    return token.ty == .lower;
}

fn isUpper(token: Token) bool {
    return token.ty == .upper;
}

fn isUpperLower(token: Token) bool {
    return isUpper(token) or isLower(token);
}

fn isIgnorable(token: Token) bool {
    return token.ty == .extend or token.ty == .format;
}

fn isClose(token: Token) bool {
    return token.ty == .close;
}

fn isSpace(token: Token) bool {
    return token.ty == .sp;
}

fn isParaSep(token: Token) bool {
    return token.ty == .cr or token.ty == .lf or token.ty == .sep;
}

fn isSATerm(token: Token) bool {
    return token.ty == .aterm or token.ty == .sterm;
}

fn isSContinue(token: Token) bool {
    return token.ty == .scontinue;
}

fn isUnallowedBeforeLower(token: Token) bool {
    return token.ty == .oletter or isUpperLower(token) or isSATerm(token) or isParaSep(token);
}

fn isAllowedBeforeLower(token: Token) bool {
    return !isUnallowedBeforeLower(token);
}

// Comptime
fn getTokens(comptime str: []const u8, comptime n: usize) [n]Token {
    var i: usize = 0;
    var cp_iter = CodePointIterator{ .bytes = str };
    var tokens: [n]Token = undefined;

    while (cp_iter.next()) |cp| : (i += 1) {
        tokens[i] = .{
            .ty = Type.get(cp),
            .code_point = cp,
            .offset = i,
        };
    }

    return tokens;
}

/// `ComptimeSentenceIterator` is like `SentenceIterator` but requires a string literal to do its work at compile time.
pub fn ComptimeSentenceIterator(comptime str: []const u8) type {
    const cp_count: usize = unicode.utf8CountCodepoints(str) catch @compileError("Invalid UTF-8.");
    if (cp_count == 0) @compileError("No code points?");
    const tokens = getTokens(str, cp_count);

    return struct {
        bytes: []const u8 = str,
        i: ?usize = null,
        start: ?Token = tokens[0],
        tokens: [cp_count]Token = tokens,

        const Self = @This();

        // Main API.
        pub fn next(self: *Self) ?Sentence {
            no_break: while (self.advance()) |current_token| {
                if (isParaSep(current_token)) {
                    var end = current_token;

                    if (current_token.is(.cr)) {
                        if (self.peek()) |p| {
                            if (p.is(.lf)) {
                                _ = self.advance();
                                end = self.current();
                            }
                        }
                    }

                    const start = self.start.?;
                    self.start = self.peek();

                    return self.emit(start, end);
                }

                if (current_token.is(.aterm)) {
                    var end = self.current();

                    if (self.peek()) |p| {
                        if (isUpper(p)) {
                            // self.i may not be the same as current token's offset due to ignorable skipping.
                            const original_i = self.i;
                            self.i = current_token.offset;
                            defer self.i = original_i;

                            if (self.prevAfterSkip(isIgnorable)) |v| {
                                if (isUpperLower(v)) continue :no_break;
                            }
                        } else if (isParaSep(p) or isLower(p) or isNumeric(p) or isSContinue(p)) {
                            continue :no_break;
                        } else if (isSpace(p)) {
                            // ATerm Sp*
                            self.run(isSpace);
                            end = self.current();
                            // Possible lower case after.
                            if (self.peek()) |pp| {
                                if (isLower(pp)) continue :no_break;
                            }
                        } else if (isClose(p)) {
                            // ATerm Close*
                            self.run(isClose);
                            if (self.peek()) |pp| {
                                // Possible ParaSep after.
                                if (isParaSep(pp)) {
                                    _ = self.advance();
                                    end = self.current();
                                    const start = self.start.?;
                                    self.start = self.peek();

                                    return self.emit(start, end);
                                }
                                // Possible spaces after.
                                if (isSpace(pp)) {
                                    // ATerm Close* Sp*
                                    self.run(isSpace);

                                    if (self.peek()) |ppp| {
                                        // Possible lower after.
                                        if (isLower(ppp)) continue :no_break;
                                        // Possible lower after some allowed code points.
                                        if (isAllowedBeforeLower(ppp)) {
                                            if (self.peekAfterSkip(isAllowedBeforeLower)) |pppp| {
                                                // ATerm Close* Sp* !(Unallowed) Lower
                                                if (isLower(pppp)) continue :no_break;
                                            }
                                        }
                                    }
                                }
                            }

                            end = self.current();
                        } else if (isSATerm(p)) {
                            self.run(isSATerm);
                            end = self.current();
                        }
                    }

                    const start = self.start.?;
                    self.start = self.peek();

                    return self.emit(start, end);
                }

                if (current_token.is(.sterm)) {
                    var end = self.current();

                    if (self.peek()) |p| {
                        if (isParaSep(p) or isSATerm(p) or isSContinue(p)) {
                            _ = self.advance();
                            end = self.current();
                        } else if (isSpace(p)) {
                            self.run(isSpace);
                            end = self.current();
                        } else if (isClose(p)) {
                            // STerm Close*
                            self.run(isClose);
                            if (self.peek()) |pp| {
                                if (isSpace(pp)) {
                                    // STerm Close* Sp*
                                    self.run(isSpace);
                                }
                            }

                            end = self.current();
                        }
                    }

                    const start = self.start.?;
                    self.start = self.peek();

                    return self.emit(start, end);
                }
            }

            return if (self.start) |start| self.emit(start, self.last()) else null;
        }

        // Token array movement.
        fn forward(self: *Self) bool {
            if (self.i) |*index| {
                index.* += 1;
                if (index.* >= self.tokens.len) return false;
            } else {
                self.i = 0;
            }

            return true;
        }

        pub fn count(self: *Self) usize {
            const original_i = self.i;
            const original_start = self.start;
            defer {
                self.i = original_i;
                self.start = original_start;
            }

            self.rewind();
            var i: usize = 0;
            while (self.next()) |_| : (i += 1) {}

            return i;
        }

        // Token array movement.
        pub fn rewind(self: *Self) void {
            self.i = null;
            self.start = self.tokens[0];
        }

        fn getRelative(self: Self, n: isize) ?Token {
            var index: usize = self.i orelse 0;

            if (n < 0) {
                if (index == 0 or -%n > index) return null;
                index -= @intCast(-%n);
            } else {
                const un: usize = @intCast(n);
                if (index + un >= self.tokens.len) return null;
                index += un;
            }

            return self.tokens[index];
        }

        fn prevAfterSkip(self: *Self, predicate: TokenPredicate) ?Token {
            if (self.i == null or self.i.? == 0) return null;

            var i: isize = 1;
            while (self.getRelative(-i)) |token| : (i += 1) {
                if (!predicate(token)) return token;
            }

            return null;
        }

        fn current(self: Self) Token {
            // Assumes self.i is not null.
            return self.tokens[self.i.?];
        }

        fn last(self: Self) Token {
            return self.tokens[self.tokens.len - 1];
        }

        fn peek(self: Self) ?Token {
            return self.getRelative(1);
        }

        fn peekAfterSkip(self: *Self, predicate: TokenPredicate) ?Token {
            var i: isize = 1;
            while (self.getRelative(i)) |token| : (i += 1) {
                if (!predicate(token)) return token;
            }

            return null;
        }

        fn advance(self: *Self) ?Token {
            const token = if (self.forward()) self.current() else return null;
            if (!isParaSep(token)) _ = self.skipIgnorables(token);

            return token;
        }

        fn run(self: *Self, predicate: TokenPredicate) void {
            while (self.peek()) |token| {
                if (!predicate(token)) break;
                _ = self.advance();
            }
        }

        fn skipIgnorables(self: *Self, end: Token) Token {
            if (self.peek()) |p| {
                if (isIgnorable(p)) {
                    self.run(isIgnorable);
                    return self.current();
                }
            }

            return end;
        }

        // Production.
        fn emit(self: Self, start_token: Token, end_token: Token) Sentence {
            const start = start_token.code_point.offset;
            const end = end_token.code_point.offset + end_token.code_point.len;

            return .{
                .bytes = self.bytes[start..end],
                .offset = start,
            };
        }
    };
}

test "Segmentation ComptimeSentenceIterator" {
    @setEvalBranchQuota(2_000);

    const input =
        \\("Go.") ("He said.")
    ;
    comptime var ct_iter = ComptimeSentenceIterator(input){};
    const n = comptime ct_iter.count();
    comptime var sentences: [n]Sentence = undefined;
    comptime {
        var i: usize = 0;
        while (ct_iter.next()) |sentence| : (i += 1) {
            sentences[i] = sentence;
        }
    }

    const s1 =
        \\("Go.") 
    ;
    const s2 =
        \\("He said.")
    ;
    const want = &[_][]const u8{ s1, s2 };

    for (sentences, 0..) |sentence, i| {
        try std.testing.expect(sentence.eql(want[i]));
    }
}
