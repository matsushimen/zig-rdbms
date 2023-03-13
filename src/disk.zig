const std = @import("std");
const File = std.fs.File;
pub const PAGE_SIZE: u64 = 4096;

pub var Page = struct{
    id: u64;
}
pub const DiskManager = struct
{
    heap_file: File,

    next_page: u64,

    const Self = @This();


    fn createOrOpen(heap_file_path: u32) File.OpenError!File {
        return std.fs.cwd().openFile(heap_file_path, .{}) catch |err| {
            if (err==File.OpenError.FileNotFound) {
                return std.fs.cwd().createFile(heap_file_path, .{});
            }
            else err;
        };
    }
    
    pub fn open(heap_file_path: u32) File.OpenError!Self {
        var heap_file = createOrOpen(heap_file_path);
        defer heap_file.close();
        return Self.new(heap_file);
    }

    pub fn new(heap_file: File) !Self {

        // ファイルサイズを取得
        const heap_file_size: u64 = heap_file.stat().size;
        var next_page_id: u64 = heap_file_size/PAGE_SIZE;

        return Self{.heap_file=heap_file, .next_page=next_page_id };

    }

    pub fn allocatePage() Page {
        var page_id = self.next_page_id;
        self.next_page_id += 1;
        return Page{.id=page_id}
    }

    pub fn write_page_data(page: Page, data: []const u8) !void {
        // オフセットを計算
        var offset = PAGE_SIZE * page.id;
        // ページ先頭へシーク
        self.heap_file.seekTo(offset);
        // データを書き込む
        self.heap_file.write(data);
    }

    pub fn read_page_data(page: Page, data: []const u8) !void {
        // オフセットを計算
        var offset = PAGE_SIZE * page.id;
        // ページ先頭へシーク
        self.heap_file.seekTo(offset);
        // データを読み出す
        self.heap_file.read(data);
    }
};

