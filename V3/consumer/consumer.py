import paho.mqtt.client as mqtt
import psycopg2
import json
import os
import requests

def get_db_password():
    url = "https://vault:8200/v1/secret/data/db_creds"
    headers = {"X-Vault-Token": os.getenv("VAULT_TOKEN", "root")}
    try:
        response = requests.get(url, headers=headers, verify=False)
        return response.json()["data"]["data"]["password"]
    except: return None

def on_connect(client, userdata, flags, rc):
    if rc == 0: client.subscribe("esp32")

def on_message(client, userdata, msg):
    db_password = get_db_password()
    if not db_password: return

    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=int(os.getenv('DB_PORT')),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=db_password
        )
        cur = conn.cursor()
        cur.execute("INSERT INTO sensor_data (payload) VALUES (%s)", (msg.payload.decode(),))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"DB Error: {e}")

client = mqtt.Client()
client.username_pw_set(os.getenv("MQTT_USER"), os.getenv("MQTT_PASSWORD"))

client.tls_set(ca_certs="/mosquitto/config/certs/ca.crt")
client.tls_insecure_set(True)

client.on_connect = on_connect
client.on_message = on_message

client.connect("mosquitto", 8883, 60)
client.loop_forever()
