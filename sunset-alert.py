#! /usr/local/bin/python3

import requests
import json
import datetime

from dateutil import parser, tz

url = 'https://api.sunrise-sunset.org/json?lat=48.74496406744937&lng=-0.9630006440686582&formatted=0'

resp = requests.get(url)
if resp.status_code == 200:
    data = json.loads(resp.text)    
    if "status" in data and data["status"] == "OK":
        print(json.dumps(data))
        sunset = parser.isoparse(data["results"]["sunset"])
        now = datetime.datetime.now(tz.UTC)
        print(sunset-now)#! /usr/local/bin/python3

