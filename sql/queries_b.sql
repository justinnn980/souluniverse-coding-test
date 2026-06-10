-- 소울톡 코딩 테스트 — Part B 쿼리 개선
-- 아래 문제 쿼리의 문제를 진단하고, 개선된 버전을 지정된 위치에 작성하세요.

-- ════════════════════════════════════════════════════════════
-- [스키마 참조] 수정 금지
-- ════════════════════════════════════════════════════════════

-- 사용자 테이블 (~50만 행)
CREATE TABLE users (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  nickname    VARCHAR(50) NOT NULL,
  gender      ENUM('M','F','N') NOT NULL,
  birth_year  SMALLINT NOT NULL,
  region      VARCHAR(30),
  status      ENUM('active','dormant','banned') DEFAULT 'active',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login  DATETIME
);

-- 상담사 테이블 (~5,000명)
CREATE TABLE counselors (
  id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id        BIGINT NOT NULL UNIQUE,
  tier           ENUM('grand_soul','soul_healer','soul_master','soul_talker') NOT NULL,
  is_online      TINYINT(1) DEFAULT 0,
  fee_per_30sec  SMALLINT NOT NULL, -- 쿠키 단위
  rating         DECIMAL(3,2),
  review_count   INT DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 상담 채팅방 테이블 (~200만 건)
CREATE TABLE chat_rooms (
  id                   BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id              BIGINT NOT NULL,
  counselor_id         BIGINT NOT NULL,
  status               ENUM('waiting','in_progress','ended','canceled') NOT NULL,
  fee_per_30sec        SMALLINT NOT NULL,
  total_billed_cookies INT DEFAULT 0,
  billing_started_at   DATETIME,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at             DATETIME,
  FOREIGN KEY (user_id)       REFERENCES users(id),
  FOREIGN KEY (counselor_id)  REFERENCES counselors(id)
);

-- 현재 인덱스: PK만 존재


-- ════════════════════════════════════════════════════════════
-- B-2-1. 일별 상담 완료 통계
-- 최근 30일간 날짜별 상담 완료 건수와 평균 쿠키 소비량 조회
-- 현재 응답 시간 5초 이상 → 개선 필요
-- ════════════════════════════════════════════════════════════

-- [문제 쿼리] 수정 금지
SELECT
  DATE_FORMAT(created_at, '%Y-%m-%d') AS consult_date,
  COUNT(*)                            AS consult_count,
  AVG(total_billed_cookies)           AS avg_cookies
FROM chat_rooms
WHERE DATE_FORMAT(created_at, '%Y-%m-%d') >= DATE_FORMAT(
    DATE_SUB(NOW(), INTERVAL 30 DAY), '%Y-%m-%d'
  )
  AND status = 'ended'
GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d')
ORDER BY consult_date;

-- [개선된 쿼리] 여기에 작성하세요
SELECT
  DATE_FORMAT(created_at, '%Y-%m-%d') AS consult_date,
  COUNT(*)                            AS consult_count,
  AVG(total_billed_cookies)           AS avg_cookies
FROM chat_rooms
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND status = 'ended'
GROUP BY DATE(created_at)
ORDER BY consult_date;

-- [CREATE INDEX] 여기에 작성하세요
CREATE INDEX idx_chatrooms_status_created
  ON chat_rooms (status, created_at);


-- ════════════════════════════════════════════════════════════
-- B-2-2. 상담사 목록 — N+1 쿼리
-- 온라인 상담사 목록 + 각 상담사의 누적 완료 상담 횟수를 단일 쿼리로 조회
--
-- 결과 컬럼: user_id, nickname, gender, birth_year, total_chat_count
-- 정렬: total_chat_count DESC
-- ════════════════════════════════════════════════════════════

-- [문제 쿼리 Step 1] 온라인 상담사 목록 조회 / 수정 금지
SELECT c.id, u.nickname, c.tier, c.fee_per_30sec, c.rating
FROM counselors c
  JOIN users u ON c.user_id = u.id
WHERE c.is_online = 1
  AND u.status = 'active';

-- [문제 쿼리 Step 2] 각 상담사마다 반복 실행됨 (N번) / 수정 금지
SELECT COUNT(*) AS total_consultations
FROM chat_rooms
WHERE counselor_id = ?
  AND status = 'ended';

-- [개선된 단일 쿼리] 여기에 작성하세요
SELECT
  u.id          AS user_id,
  u.nickname,
  u.gender,
  u.birth_year,
  COUNT(cr.id)  AS total_chat_count
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

-- [CREATE INDEX] 여기에 작성하세요
CREATE INDEX idx_chatrooms_counselor_status
  ON chat_rooms (counselor_id, status);

CREATE INDEX idx_counselors_isonline
  ON counselors (is_online);