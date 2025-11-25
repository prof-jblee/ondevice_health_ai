import sqlite3
import os
from datetime import datetime

# 앱 내부 저장소 경로에 DB 파일 생성
DB_FILE = os.path.join(os.environ["HOME"], "fitbit_data.db")

def get_connection():
    return sqlite3.connect(DB_FILE)

def init_db():
    """테이블이 없으면 생성"""
    conn = get_connection()
    cursor = conn.cursor()
    
    # 걸음 수 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS fitbit_steps (
            timestamp TEXT,
            value INTEGER,
            PRIMARY KEY (timestamp, value)
        )
    ''')
    conn.commit()

    # 심박 수 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS fitbit_heartrates (
            timestamp TEXT,
            value REAL,
            PRIMARY KEY (timestamp, value)
        )
    ''')
    conn.commit()

    # 휴식기 심박 수(RHR) 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS fitbit_resting_heartrates (
            timestamp TEXT,
            value REAL,
            PRIMARY KEY (timestamp, value)
        )
    ''')
    conn.commit()

    # 조도 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS fitbit_lights (
            timestamp TEXT,
            value REAL,
            PRIMARY KEY (timestamp, value)
        )
    ''')
    conn.commit()

    conn.close()

def insert_step(timestamp_str, step_count):
    """현재 시간과 걸음 수 저장"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # 데이터 삽입
        cursor.execute("INSERT INTO fitbit_steps (timestamp, value) VALUES (?, ?)", (timestamp_str, int(step_count)))
        
        conn.commit()
        conn.close()
        return f"성공: {now}에 {step_count}보 저장됨"
    
    except sqlite3.IntegrityError:
        conn.close()
        return "저장 실패: 이미 동일한 시간/데이터가 존재합니다."

    except Exception as e:
        return f"에러 발생: {str(e)}"
    
def insert_heartrate(hr_value):
    """현재 시간과 심박 수 저장"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # 현재 시간 (YYYY-MM-DD HH:MM:SS 형식)
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 데이터 삽입
        cursor.execute("INSERT INTO fitbit_heartrates (timestamp, value) VALUES (?, ?)", (now, int(hr_value)))
        
        conn.commit()
        conn.close()
        return f"성공: {now}에 {hr_value}bpm 저장됨"
    
    except sqlite3.IntegrityError:
        conn.close()
        return "저장 실패: 이미 동일한 시간/데이터가 존재합니다."

    except Exception as e:
        return f"에러 발생: {str(e)}"
    
def insert_resting_heartrate(rhr_value):
    """현재 시간과 휴식기 심박 수 저장"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # 현재 시간 (YYYY-MM-DD HH:MM:SS 형식)
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 데이터 삽입
        cursor.execute("INSERT INTO fitbit_resting_heartrates (timestamp, value) VALUES (?, ?)", (now, int(rhr_value)))
        
        conn.commit()
        conn.close()
        return f"성공: {now}에 {rhr_value}bpm 저장됨"
    
    except sqlite3.IntegrityError:
        conn.close()
        return "저장 실패: 이미 동일한 시간/데이터가 존재합니다."

    except Exception as e:
        return f"에러 발생: {str(e)}"
    
def insert_light(light_value):
    """현재 시간과 조도 값 저장"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # 현재 시간 (YYYY-MM-DD HH:MM:SS 형식)
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 데이터 삽입
        cursor.execute("INSERT INTO fitbit_lights (timestamp, value) VALUES (?, ?)", (now, int(light_value)))
        
        conn.commit()
        conn.close()
        return f"성공: {now}에 {light_value}lux 저장됨"
    
    except sqlite3.IntegrityError:
        conn.close()
        return "저장 실패: 이미 동일한 시간/데이터가 존재합니다."

    except Exception as e:
        return f"에러 발생: {str(e)}"

def get_total_count():
    """총 행 개수 리턴"""
    try:
        init_db()
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM fitbit_steps")
        count = cursor.fetchone()[0]
        
        conn.close()
        return count # 정수형 리턴
    except Exception as e:
        return -1 # 에러 시 -1 리턴
    
def reset_db():
    """테이블을 삭제하고 다시 생성하여 초기화"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # 테이블 삭제 (DROP)
        cursor.execute("DROP TABLE IF EXISTS fitbit_steps")
        cursor.execute("DROP TABLE IF EXISTS fitbit_heartrates")
        cursor.execute("DROP TABLE IF EXISTS fitbit_resting_heartrates")
        cursor.execute("DROP TABLE IF EXISTS fitbit_lights")        
        
        conn.commit()
        conn.close()
        
        # 다시 생성 (빈 테이블 상태로 만듦)
        init_db()
        
        return "DB 초기화 완료 (모든 데이터 삭제됨)"
    except Exception as e:
        return f"초기화 실패: {str(e)}"