const std = @import("std");

pub const PathWithParams = struct { path: []const u8, params: *std.StringHashMap([]const u8) };
