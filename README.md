### Cài đặt tự động trên Windows
Chạy PowerShell với quyền Administrator

```powershell
irm https://go.bibica.net/opera-proxy | iex
```
Mặc định tạo sẵn tạo 3 location Opera cung cấp là Singapore, United States (Virginia), Europe (Netherlands) chạy cho nhiều tình huống, nhu cầu khác nhau

```
Opera Socks5 Proxy installed successfully!

IP: 127.0.0.1
Port: 10001
Location: Singapore

IP: 127.0.0.1
Port: 10002
Location: Americas

IP: 127.0.0.1
Port: 10003
Location: Europe

Config file: C:\opera-proxy\opera-proxy.vbs
Shortcut: C:\Users\bibica\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\opera-proxy.lnk
```
Toàn bộ cài đặt sẽ lưu tại `C:\opera-proxy` và `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup`, không muốn dùng nữa thì vào 2 đường dẫn này xóa đi là được

Script duy trì mỗi khi khởi động máy, tự chạy file `opera-proxy.vbs`, kết nối ngẫu nhiên tới 1 endpoint nhanh nhất (hoặc khỏe nhất), tuy thế tỷ lệ endpoint nhanh và chậm của Singapore nó khá lệch, cụm nhanh download 8MB/s – 20MB/s, cụm chậm xuống 200kb/s???

<img src="https://img.bibica.net/0dXmYNxZ.png" alt="0dXmYNxZ">

- Có thể bật chạy lại `opera-proxy.vbs`, nếu “tình cờ” vào cụm nhanh thì dùng tiếp (thường kết nối lại 2-4 lần sẽ gặp cụm nhanh) 
- Hoặc bật chạy 1 trong 2 file `opera-proxy-singapore-1.vbs`, `opera-proxy-singapore-2.vbs` làm sẵn, 2 endpoint này khá nhanh
