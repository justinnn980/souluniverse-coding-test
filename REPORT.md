# 코딩 테스트 제출 리포트

---

## Part A — Flutter 버그 수정

### 수정한 버그 목록

| # | 파일 경로 | 수정 내용 | 원인 분석 |
|---|-----------|-----------|-----------|
| 1 |home_page.dart | _HomeBody의 context watch로 변경|기존에는 상태를 구독하지 않는 context를 사용해 데이터 변경 시 UI가 다시 빌드되지 않았다. watch로 변경해서 상태 변경을 감지|
| 2 |me_state.dart | removeFavoriteCounselor의 where 조건을 !=으로 수정 | where는 제거가 아니라 필터이기 때문에 남길 조건을 작성하기위해서 ==가 아닌 != 로 변경|
| 3 |consultation_room_page.dart |setState 추가 |바뀐 변수 값을 Widget에게 알려주는 함수가 없어서 추가|
| 4 |consultation_room_page.dart | _sendMessage에서 전송 후 _messages에 메시지 추가| Repository에 전송 요청만 하고 화면의 _messages에 추가하는 코드가 없어서 메시지를 보내도 채팅창에 표시되지 않았다|
| 5 |consultation_room_page.dart | MessageBubble에 currentUserId 전달| currentUserId가 null이라 _isMine이 항상 false가 되어 내가 보낸 메시지도 상대방 메시지처럼 왼쪽에 표시됐다|

### 기타 의견

사용자 입장에서 봤을때 채팅방 우측에 스크롤을 넣어서 사용자가 올리고 내릴 수 있게 변경하였으면 좋겠다고 생각하여 추가 하였다.

---

## Part B — SQL 쿼리 개선

### B-2-1. 일별 상담 완료 통계

**문제점:**

**개선된 쿼리:**

```sql
-- 여기에 작성해주세요
```

**개선 이유:**

---

### B-2-2. 상담사 목록 N+1 쿼리

**문제점:**

**개선된 쿼리:**

```sql
-- 여기에 작성해주세요
```

**개선 이유:**
