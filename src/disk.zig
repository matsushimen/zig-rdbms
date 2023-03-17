const std = @import("std");
const File = std.fs.File;
pub const PAGE_SIZE: u64 = 4096;

pub const Page = struct{
    id: u64,
};

fn createOrOpen(heap_file_path: []const u8) File.OpenError!File {
    return std.fs.cwd().openFile(heap_file_path, .{}) catch |err| {
        if(err == File.OpenError.FileNotFound) {
            return std.fs.cwd().createFile(heap_file_path, .{});
        }
        else {
            return err;
        }
    };
}


pub const DiskManager = struct
{
    heap_file: File,

    next_page: u64,

    const Self = @This();


    

    pub fn open(heap_file_path: []const u8) File.OpenError!Self {
        var heap_file = try createOrOpen(heap_file_path);
        defer heap_file.close();
        return Self.new(heap_file);
    }

    pub fn new(heap_file: File) !Self {

        // ファイルサイズを取得
        const heap_file_size: u64 = (try heap_file.stat()).size;
        var next_page_id: u64 = heap_file_size/PAGE_SIZE;

        return Self{.heap_file=heap_file, .next_page=next_page_id };

    }

    pub fn allocatePage() Page {
        var page_id = Self.next_page_id;
        Self.next_page_id += 1;
        return Page{.id=page_id};
    }

    pub fn write_page_data(page: Page, data: []const u8) !void {
        // オフセットを計算
        var offset = PAGE_SIZE * page.id;
        // ページ先頭へシーク
        Self.heap_file.seekTo(offset);
        // データを書き込む
        Self.heap_file.write(data);
    }

    pub fn read_page_data(page: Page, data: []const u8) !void {
        // オフセットを計算
        var offset = PAGE_SIZE * page.id;
        // ページ先頭へシーク
        Self.heap_file.seekTo(offset);
        // データを読み出す
        Self.heap_file.read(data);
    }
};

test "Page" {
    var page1 = Page{.id=1};
    var page11 = Page{.id=1};
    try std.testing.expectEqual(page1, page11);
}

test "createOrOpen" {
    var file =  createOrOpen("/dev/null");
    try std.testing.expectEqual(@TypeOf(file), File.OpenError!File);
}

test "Disk.open" {
    const dm = DiskManager;
    var heap = dm.open("/dev/null");
    try std.testing.expectEqual(@TypeOf(heap), File.OpenError!DiskManager);
}

test "Disk.allocatePage" {
    const dm = DiskManager;
    var heap = try dm.open("/dev/null");
    var page = heap.allocatePage();
    try std.testing.expectEqual(@TypeOf(page), Page);
}