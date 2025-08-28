-- 확장 설치 (존재하지 않으면)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;

-- 확인용 쿼리(주석):
--   \dx