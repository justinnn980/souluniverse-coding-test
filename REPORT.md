# 코딩 테스트 제출 리포트

---

## Part A — Flutter 버그 수정

### 수정한 버그 목록

| # | 파일 경로 | 수정 내용 | 원인 분석 |
|---|-----------|-----------|-----------|
| 1 | home_page.dart | _HomeBody의 context.watch로 변경 | context.read는 상태를 구독하지 않아 MeState가 변경돼도 UI가 리빌드되지 않았다. watch로 변경해 상태 변경을 감지하도록 했다 |
| 2 | me_state.dart | removeFavoriteCounselor의 where 조건을 !=으로 수정 | where는 남길 조건을 쓰는 필터라 ==는 삭제 대상만 남기는 반전 동작을 했다. !=으로 수정해 삭제 대상을 제외한 나머지를 유지하도록 했다 |
| 3 | consultation_room_page.dart | _loadInitialMessages, _loadMoreMessages에 setState 추가 | 변수를 변경해도 setState 없이는 Flutter가 인지하지 못해 로딩 인디케이터와 메시지 목록이 갱신되지 않았다 |
| 4 | consultation_room_page.dart | _connectFirestore listen에 setState 및 mounted 체크 추가 | 스트림 콜백에서 setState가 없어 실시간 메시지가 화면에 표시되지 않았고, mounted 체크가 없어 화면 종료 후 콜백이 도착하면 에러가 발생했다 |
| 5 | consultation_room_page.dart | dispose에 _messageSubscription.cancel() 추가 | 화면 종료 시 스트림을 취소하지 않아 메모리 누수와 dispose 후 setState 호출 에러가 발생했다 |
| 6 | consultation_room_page.dart | _sendMessage에서 전송 후 _messages에 메시지 추가 | Repository에 전송 요청만 하고 화면의 _messages에 추가하는 코드가 없어서 메시지를 보내도 채팅창에 표시되지 않았다 |
| 7 | consultation_room_page.dart | MessageBubble에 currentUserId 전달 | currentUserId가 null이라 _isMine이 항상 false가 되어 내가 보낸 메시지도 상대방 메시지처럼 왼쪽에 표시됐다 |

### 기타 의견

사용자 입장에서 봤을때 채팅방 우측에 스크롤을 넣어서 사용자가 올리고 내릴 수 있게 변경하였으면 좋겠다고 생각하여 추가 하였다.

Claude Code(AI)를 활용해 버그의 위치와 원인 파악에 참고했으며,
의사결정과 코드 수정은 직접 판단하고 작성했다.
---

## Part B — SQL 쿼리 개선

### B-2-1. 일별 상담 완료 통계

**문제점:**
WHERE 절에서 컬럼 값을 그대로 비교해야 MySQL이 인덱스를 사용할 수 있다. 함수로 감싸면 인덱스를 타지 못한다.

**개선된 쿼리:**

```sql
SELECT
  DATE_FORMAT(created_at, '%Y-%m-%d') AS consult_date,
  COUNT(*)                            AS consult_count,
  AVG(total_billed_cookies)           AS avg_cookies
FROM chat_rooms
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND status = 'ended'
GROUP BY DATE(created_at)
ORDER BY consult_date;
```

**개선 이유:**
그래서 DATE_FORMAT(created_at, ...) 대신 created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)로 변경해 인덱스 range scan이 가능하게 했다

**인덱스**

```sql
CREATE INDEX idx_chatrooms_status_created
  ON chat_rooms (status, created_at);
```

**이 인덱스가 효과적인 이유**
status = 'ended'로 먼저 범위를 좁히고
그 안에서 created_at 최근 30일치만 스캔하기 때문입니다.
---

### B-2-2. 상담사 목록 N+1 쿼리

**문제점:**
Step 1에서 온라인 상담사 N명 조회 - 1번
Step 2에서 각 상담사마다 상담 횟수 조회 - N번
상담사가 100명이면 총 101번 쿼리 실행

**개선된 쿼리:**

```sql
SELECT
  u.id AS user_id,
  u.nickname,
  u.gender,
  u.birth_year,
  COUNT(cr.id) AS total_chat_count
FROM counselors c
  JOIN users u
    ON c.user_id = u.id
  LEFT JOIN chat_rooms cr
    ON cr.counselor_id = c.id
    AND cr.status = 'ended'
WHERE c.is_online = 1
  AND u.status = 'active'
GROUP BY u.id, u.nickname, u.gender, u.birth_year
ORDER BY total_chat_count DESC;
```

**개선 이유:**
Step 2를 N번 반복하는 대신 LEFT JOIN으로 chat_rooms를 한 번에 연결해 쿼리 실행 횟수를 1번으로 줄였다. LEFT JOIN을 사용한 이유는 상담 이력이 없는 상담사도 결과에 포함시키기 위해서이고, COUNT(cr.id)를 사용한 이유는 매칭되는 행이 없을 때 null을 0으로 정확하게 카운트하기 위해서다.

**인덱스:**

```sql
CREATE INDEX idx_chatrooms_counselor_status
  ON chat_rooms (counselor_id, status);

CREATE INDEX idx_counselors_isonline
  ON counselors (is_online);
  ```
  
(counselor_id, status) 복합 인덱스를 생성해 200만 건의 chat_rooms에서
특정 상담사의 완료 상담만 풀 스캔 없이 바로 찾을 수 있게 했다.

