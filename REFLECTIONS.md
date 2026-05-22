# REFLECTIONS — G10 costctl W6 Side Challenge

## 1. Multi-account: To run `costctl` against 100 AWS accounts

Để chạy `costctl` trên 100 AWS accounts, cần thay đổi theo hướng:

- **Cross-account IAM roles**: Mỗi account cần có một IAM role (ví dụ `costctl-readonly`) với trust policy cho phép account trung tâm assume. Thay vì dùng credentials cố định, `costctl` sẽ gọi `sts.assume_role(RoleArn=...)` để lấy temporary credentials cho từng account.
- **Profile loop**: Có thể dùng AWS Organizations để list tất cả account IDs, sau đó loop qua từng account, assume role, tạo boto3 session riêng, rồi chạy các command.
- **Aggregated output**: Kết quả nên được gom lại thành CSV hoặc JSON với cột `account_id` để dễ so sánh chi phí giữa các accounts. Ví dụ: `costctl cost --tag Application=HealthBot --days 7 --all-accounts > report.csv`.
- **Thách thức thực tế**: Cost Explorer chỉ available ở `us-east-1` và cần được enable per-account. Tag activation cũng phải làm riêng cho từng account.

## 2. `idle` vs Trusted Advisor: Khi nào tin cái nào hơn?

- **Tin `idle` (24h window) hơn** khi: cần phát hiện nhanh instance vừa bị bỏ quên sau một buổi demo/lab (ví dụ W6 practice instances). Window ngắn phản ánh trạng thái hiện tại chính xác hơn. Cũng hữu ích khi workload có pattern theo giờ (batch job chạy ban đêm).
- **Tin Trusted Advisor (14 ngày) hơn** khi: đánh giá instance production có traffic thất thường — ví dụ một web server chỉ bận vào cuối tuần sẽ bị `idle` (24h) đánh dấu sai vào thứ Tư. 14 ngày cho bức tranh đầy đủ hơn về usage pattern thực sự.
- **Kết luận**: Dùng `idle` để triage nhanh, dùng Trusted Advisor để confirm trước khi terminate production resources.

## 3. `clean --apply` blast radius

Nếu vô tình chạy `clean --tag Environment=dev --apply` trên account dùng chung:

- **Muốn có**: Tag ownership convention rõ ràng — ví dụ chỉ terminate nếu resource có thêm tag `managed-by=costctl` hoặc `purpose=practice`. Một tag đơn như `Environment=dev` quá rộng.
- **Muốn có**: Dry-run bắt buộc trước apply — yêu cầu user chạy dry-run và confirm số lượng resource trước khi apply.
- **Muốn có**: IAM permission boundary — role chạy `costctl` chỉ được terminate resource trong một account/region cụ thể, không phải toàn bộ.
- **Muốn có**: CloudTrail + SNS alert khi có bulk terminate > N resources trong 1 phút.

## 4. AI assistance

Khoảng **85%** code logic được generate bởi AI (Kiro/Claude) dựa trên docstring spec có sẵn. Phần chủ động chỉnh sửa:

- Output format của `list` command (căn chỉnh cột cho dễ đọc)
- Logic merge tags trong `_tag_s3` (AI ban đầu bỏ qua bước fetch existing tags trước khi put)
- `_find_targets` trong `clean_cmd` — thêm filter trực tiếp vào `describe_instances` thay vì fetch all rồi filter trong Python (hiệu quả hơn với large accounts)

Phần quan trọng nhất vẫn là **đọc docstring và test cases** để hiểu spec trước khi để AI generate — garbage in, garbage out.

## 5. W7 carry-over

**Giữ lại:**
- `list` — core utility, sẽ extend thêm `--output json/csv` cho multi-account aggregation
- `cost` — quan trọng nhất cho W7 cost optimization story
- `tag` — cần thiết để enforce tagging policy ở scale

**Bỏ hoặc redesign:**
- `terminate` / `clean` — quá nguy hiểm để chạy trực tiếp ở multi-account production. W7 nên thay bằng workflow có approval step (ví dụ tạo Jira ticket hoặc Slack approval trước khi terminate).
- `idle` — logic 24h window không đủ tin cậy cho production. W7 nên dùng Trusted Advisor API hoặc Compute Optimizer thay thế.
