pub fn getKeValueBySeparator(val: []const u8, separator: u8) struct { key: []const u8, value: []const u8 } {
    var separatorIndex: usize = 0;

    for (val, 0..) |char, i| {
        if (char == separator) separatorIndex = i;
    }
    const separatorId = separatorIndex;

    return .{ .key = val[0..separatorId], .value = val[separatorId + 1 ..] };
}
