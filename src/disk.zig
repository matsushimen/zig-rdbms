const std = @import("std");
const File = std.fs.File;
const testing = std.testing;
const assert = testing.assert;
const expectEqual = testing.expectEqual;

const PAGE_SIZE: usize = 4096;

const DiskManager = struct {
    pub const Self = @This();

    heap_file: File,
    next_page_id: usize,

    pub fn open(heap_file_path: []const u8) !Self {
        var heap_file = try std.fs.cwd().createFile(heap_file_path, .{});

        return Self {
            .heap_file = heap_file,
            .next_page_id = 0,
        };
    }

    pub fn allocate_page(self: *Self) !usize {
        const page_id = self.next_page_id;
        self.next_page_id += 1;
        return page_id;
    }

    pub fn write_page_data(self: *Self, page_id: usize, data: []const u8) !void {
        // オフセットを計算
        const offset = PAGE_SIZE * page_id;
        // ページ先頭へシーク
        try self.heap_file.seekTo(offset);
        // データを書き込む
        try self.heap_file.writeAll(data);
    }

    pub fn read_page_data(self: *Self, page_id: usize, data: []u8) !usize {
        // オフセットを計算
        const offset = PAGE_SIZE * page_id;
        // ページ先頭へシーク
        try self.heap_file.seekTo(offset);

        // ファイルが読み取り用に開かれていることを確認
        const access_mode = try self.heap_file.getAccessMode();
        if (access_mode & .readable == 0) {
            return error.NotOpenForReading;
        }

        // データを読み出す
        return try self.heap_file.read(data);
    }
};

test "test DiskManager" {
    // ファイル名
    const heap_file_path = "test_heap_file.db";
    defer std.fs.cwd().deleteFile(heap_file_path) catch {};

    // DiskManagerを開く
    var dm = try DiskManager.open(heap_file_path);

    // ページを割り当てて、書き込み、読み出し
    const page = try dm.allocate_page();
    const data: []const u8 = "Hello, world!";
    try dm.write_page_data(page, data);
    var buf: [PAGE_SIZE]u8 = undefined;
    var bytes_read = try dm.read_page_data(page, buf[0..]);
    try expectEqual(bytes_read, data.len);
    try expectEqual(data, buf[0..bytes_read]);

    // 2つめのページを割り当て、書き込み、読み出し
    const page2 = try dm.allocate_page();
    const data2: []const u8 = "Goodbye, world!";
    try dm.write_page_data(page2, data2);
    var buf2: [data2.len]u8 = undefined;
    const bytes_read2 = try dm.read_page_data(page2, buf2[0..]);
    try expectEqual(bytes_read2, data2.len);
    try expectEqual(data2, buf2[0..bytes_read2]);
}
