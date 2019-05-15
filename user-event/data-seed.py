import json
import requests
import xmltodict

import userevent
import config
import time

#sleep to allow other services to spin up
time.sleep(20)

userevent.makequeue()

#load datafile
with open(config.datafile, 'r') as f:
    datastore = json.load(f)
    for d in datastore:
        userevent.postmessage(d)
