# TiengNhatVaKeToan Native

App iPad native cho luyện JLPT N1/Boki, tách riêng khỏi repo web cũ.

## Mục tiêu

- Chạy bằng Xcode như một app iPad native.
- Dùng SwiftUI để hiển thị đề.
- Dùng PencilKit cho phần nháp Apple Pencil để viết mượt hơn Safari/canvas web.
- Dữ liệu đề được copy từ bản web/PWA vào `TiengNhatVaKeToanNative/ExamData`.

## iPadOS 26.5

Project được cấu hình iPad-only và dùng SDK mới nhất mà Xcode đang cài hỗ trợ. Khi máy có Xcode hỗ trợ iPadOS 26.5, project đã đặt `IPHONEOS_DEPLOYMENT_TARGET = 26.5` và `TARGETED_DEVICE_FAMILY = 2` để ưu tiên iPadOS 26.5, iPad-only.

Máy hiện tại đang trỏ `xcodebuild` vào Command Line Tools, nên muốn build bằng terminal cần chọn Xcode thật:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Sau đó mở `TiengNhatVaKeToanNative.xcodeproj` bằng Xcode và chọn iPad simulator hoặc iPad thật để chạy.
