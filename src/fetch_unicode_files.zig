const std = @import("std");

fn fetchFile(
    comptime dirname: []const u8,
    comptime filename: []const u8,
    comptime unicode_url: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // our http client, this can make multiple requests
    // (and is even threadsafe, although individual requests are not).
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // we can `catch unreachable` here because we can guarantee that this is a valid url.
    const uri = std.Uri.parse(unicode_url ++ filename) catch unreachable;

    // these are the headers we'll be sending to the server
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("accept", "text/plain"); // tell the server we'll accept anything
    try headers.append("accept-encoding", "identity");

    // make the connection and set up the request
    var req = try client.request(.GET, uri, headers, .{});
    defer req.deinit();

    // I'm making a GET request, so I don't need this, but I'm sure someone will.
    // req.transfer_encoding = .chunked;

    // send the request and headers to the server.
    try req.start();

    // try req.writer().writeAll("Hello, World!\n");
    // try req.finish();

    // wait for the server to send use a response
    try req.wait();

    // read the content-type header from the server, or default to text/plain
    //const content_type = req.response.headers.getFirstValue("content-type") orelse "text/plain";

    // read the entire response body, but only allow it to allocate 8kb of memory
    var body_reader = req.reader();

    // Output dir
    var cwd = std.fs.cwd();
    try cwd.makePath(dirname);

    // Output file
    if (cwd.access(dirname ++ filename, .{})) {
        std.log.debug("\tSkipping existing file: {s}", .{dirname ++ filename});
        return; // file already exists
    } else |_| {}

    var file = try cwd.createFile(dirname ++ filename, .{});
    defer file.close();
    var file_writer = std.io.bufferedWriter(file.writer());

    var buf: [4096]u8 = undefined;

    while (true) {
        const n = try body_reader.readAll(&buf);
        if (n == 0) break;
        _ = try file_writer.write(buf[0..n]);
    }

    try file_writer.flush();
}

pub fn main() !void {
    std.log.info("Fetching Unicode files from the Internet...", .{});

    const aux_files = [_][]const u8{
        "GraphemeBreakProperty.txt",
        "GraphemeBreakTest.txt",
        "SentenceBreakProperty.txt",
        "SentenceBreakTest.txt",
        "WordBreakProperty.txt",
        "WordBreakTest.txt",
    };

    const ext_files = [_][]const u8{
        "DerivedCombiningClass.txt",
        "DerivedEastAsianWidth.txt",
        "DerivedGeneralCategory.txt",
        "DerivedNumericType.txt",
    };

    const ucd_files = [_][]const u8{
        "Blocks.txt",
        "CaseFolding.txt",
        "DerivedCoreProperties.txt",
        "DerivedNormalizationProps.txt",
        "HangulSyllableType.txt",
        "NormalizationTest.txt",
        "PropList.txt",
        "UnicodeData.txt",
    };

    var handles: [aux_files.len + ext_files.len + ucd_files.len + 2]std.Thread = undefined;
    comptime var i: usize = 0;

    inline for (aux_files) |filename| {
        handles[i] = try std.Thread.spawn(.{}, fetchFile, .{
            "zig-cache/_ziglyph-data/ucd/auxiliary/",
            filename,
            "https://www.unicode.org/Public/15.0.0/ucd/auxiliary/",
        });

        i += 1;
    }

    inline for (ext_files) |filename| {
        handles[i] = try std.Thread.spawn(.{}, fetchFile, .{
            "zig-cache/_ziglyph-data/ucd/extracted/",
            filename,
            "https://www.unicode.org/Public/15.0.0/ucd/extracted/",
        });

        i += 1;
    }

    inline for (ucd_files) |filename| {
        handles[i] = try std.Thread.spawn(.{}, fetchFile, .{
            "zig-cache/_ziglyph-data/ucd/",
            filename,
            "https://www.unicode.org/Public/15.0.0/ucd/",
        });

        i += 1;
    }

    handles[i] = try std.Thread.spawn(.{}, fetchFile, .{
        "zig-cache/_ziglyph-data/ucd/emoji/",
        "emoji-data.txt",
        "https://www.unicode.org/Public/15.0.0/ucd/emoji/",
    });

    i += 1;

    handles[i] = try std.Thread.spawn(.{}, fetchFile, .{
        "zig-cache/_ziglyph-data/uca/",
        "allkeys.txt",
        "https://www.unicode.org/Public/UCA/15.0.0/",
    });

    inline for (handles) |handle| handle.join();

    std.log.info("Fetching done!", .{});
}
