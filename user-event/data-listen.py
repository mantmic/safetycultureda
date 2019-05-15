import userevent
import time
import config
import psycopg2
import json
from datetime import datetime

#docker run -it --rm python:2.7


def dbinsert(message):
    message = json.loads(message)
    conn = psycopg2.connect(dbname= config.dbname, user=config.dbuser, password=config.dbuser, host = config.dbhost, port = config.dbport)
    cur = conn.cursor()
    cur.execute("INSERT INTO sc.sc_user_event ( user_id, platform, event_ts, event_type, first_event) VALUES (%s, %s, %s, %s, %s)", (message.get('user_id'), message.get('platform'),datetime.strptime(message.get('event_time'), '%Y-%m-%dT%H:%M:%S'), message.get('event_type'), message.get('first_event')))
    conn.commit()
    cur.close()
    conn.close()
    print(message)

# listen for message, post to database if message, otherwise sleep
while(True):
    message = userevent.getmessage()
    if message.get('success') == True:
            dbinsert(message.get('message'))
    else:
        time.sleep(5)
