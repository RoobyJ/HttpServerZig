const std = @import("std");
const net = std.net;
const fs = std.fs;
const mem = std.mem;
const expect = std.testing.expect;
const endpoints = @import("Endpoints.zig");
const Allocator = std.mem.Allocator;
const Request = @import("Models/Request.zig");
const Response = @import("Models/Response.zig");
const Endpoints = @import("Endpoints.zig");
const StatusCode = @import("Models/StatusCode.zig");
const HttpHeader = @import("Models/HttpHeader.zig");

pub const ServeFileError = error{
    HeaderMalformed,
    MethodNotSupported,
    ProtoNotSupported,
    UnknownMimeType,
};

const mimeTypes = .{
    .{ ".html", "text/html" },
    .{ ".css", "text/css" },
    .{ ".png", "image/png" },
    .{ ".jpg", "image/jpeg" },
    .{ ".gif", "image/gif" },
};

const HeaderNames = enum {
    Host,
    @"User-Agent",
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var endpointMap = std.StringHashMap(*const fn (Request.request) Response.response).init(allocator);

    std.debug.print("Starting server\n", .{});
    try addEndpoints(&endpointMap);
    const self_addr = try net.Address.resolveIp("127.0.0.1", 5000);
    var listener = try self_addr.listen(.{ .reuse_address = true });
    std.debug.print("Listening on {}\n", .{self_addr});

    while (listener.accept()) |conn| {
        std.debug.print("Accepted connection from: {}\n", .{conn.address});
        var recv_buf: [4096]u8 = undefined;
        var recv_total: usize = 0;
        while (conn.stream.read(recv_buf[recv_total..])) |recv_len| {
            if (recv_len == 0) break;
            recv_total += recv_len;
            if (mem.containsAtLeast(u8, recv_buf[0..recv_total], 1, "\r\n\r\n")) {
                break;
            }
        } else |read_err| {
            return read_err;
        }
        const recv_data = recv_buf[0..recv_total];
        if (recv_data.len == 0) {
            // Browsers (or firefox?) attempt to optimize for speed
            // by opening a connection to the server once a user highlights
            // a link, but doesn't start sending the request until it's
            // clicked. The request eventually times out so we just
            // go agane.
            std.debug.print("Got connection but no header!\n", .{});
            continue;
        }
        const header = try parseHeader(recv_data);

        const path = try parsePath(header.requestLine);
        // here handle which fn
        // const
        const request = Request.request{ .header = header, .body = "" };
        const result: ?*const fn (Request.request) Response.response = endpointMap.get(path);
        if (result) |endpoint| {
            const response: Response.response = endpoint(request);
            // const mime = mimeForPath(path);
            // const buf = openLocalFile(path) catch |err| {
            //     if (err == error.FileNotFound) {
            //         _ = try conn.stream.writer().write(http404());
            //         continue;
            //     } else {
            //         return err;
            //     }
            // };

            std.debug.print("SENDING----\n", .{});
            const responseString = try response.getResponseHeader(allocator);
            std.debug.print("test----{s}\n", .{responseString});
            _ = try conn.stream.writer().write(responseString);
            _ = try conn.stream.writer().write(response.message);
            std.debug.print("SENDED----\n", .{});
        } else {
            // doesn't exists need to handle it somehow
        }
    } else |err| {
        std.debug.print("error in accept: {}\n", .{err});
    }
}

fn addEndpoints(map: *std.hash_map.HashMap([]const u8, *const fn (Request.request) Response.response, std.hash_map.StringContext, 80)) !void {
    try map.*.put("/index.html", Endpoints.home);
}

pub fn parseHeader(header: []const u8) !HttpHeader.httpHeader {
    var headerStruct = HttpHeader.httpHeader{
        .requestLine = undefined,
        .host = undefined,
        .userAgent = undefined,
    };
    var headerIter = mem.tokenizeSequence(u8, header, "\r\n");
    headerStruct.requestLine = headerIter.next() orelse return ServeFileError.HeaderMalformed;
    while (headerIter.next()) |line| {
        const nameSlice = mem.sliceTo(line, ':');
        if (nameSlice.len == line.len) return ServeFileError.HeaderMalformed;
        const headerName = std.meta.stringToEnum(HeaderNames, nameSlice) orelse continue;
        const headerValue = mem.trimLeft(u8, line[nameSlice.len + 1 ..], " ");
        switch (headerName) {
            .Host => headerStruct.host = headerValue,
            .@"User-Agent" => headerStruct.userAgent = headerValue,
        }
    }
    return headerStruct;
}

pub fn parsePath(requestLine: []const u8) ![]const u8 {
    var requestLineIter = mem.tokenizeScalar(u8, requestLine, ' ');
    const method = requestLineIter.next().?;
    if (!mem.eql(u8, method, "GET")) return ServeFileError.MethodNotSupported;
    const path = requestLineIter.next().?;
    if (path.len <= 0) return error.NoPath;
    const proto = requestLineIter.next().?;
    if (!mem.eql(u8, proto, "HTTP/1.1")) return ServeFileError.ProtoNotSupported;
    if (mem.eql(u8, path, "/")) {
        return "/index.html";
    }
    return path;
}

pub fn openLocalFile(path: []const u8) ![]u8 {
    const localPath = path[1..];
    const file = fs.cwd().openFile(localPath, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("File not found: {s}\n", .{localPath});
            return error.FileNotFound;
        },
        else => return err,
    };
    defer file.close();
    std.debug.print("file: {}\n", .{file});
    const memory = std.heap.page_allocator;
    const maxSize = std.math.maxInt(usize);
    return try file.readToEndAlloc(memory, maxSize);
}

pub fn http404() []const u8 {
    return "HTTP/1.1 404 NOT FOUND \r\n" ++
        "Connection: close\r\n" ++
        "Content-Type: text/html; charset=utf8\r\n" ++
        "Content-Length: 9\r\n" ++
        "\r\n" ++
        "NOT FOUND";
}

pub fn mimeForPath(path: []const u8) []const u8 {
    const extension = std.fs.path.extension(path);
    inline for (mimeTypes) |kv| {
        if (mem.eql(u8, extension, kv[0])) {
            return kv[1];
        }
    }
    return "application/octet-stream";
}