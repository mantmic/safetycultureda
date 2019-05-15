import json
import requests
import xmltodict

import config

queueaddress = config.queueaddress

#make the queue
def makequeue():
    response = requests.get(queueaddress + '/?Action=CreateQueue&QueueName=userevent')
    return(response)

def postmessage(message):
    response = requests.get(queueaddress + '/userevent',params={'QueueName':'userevent', 'Action': 'SendMessage', 'MessageBody':json.dumps(message, ensure_ascii=False)})
    return(response)

def deletemessage(receipthandle):
    response = requests.get(queueaddress + '/userevent',params={'QueueName':'userevent', 'Action': 'DeleteMessage', 'ReceiptHandle':receipthandle})
    return(response)

def getmessage():
    response = requests.get(queueaddress + '/userevent',params={'QueueName':'userevent', 'Action': 'ReceiveMessage'})
    body = xmltodict.parse(response.content)
    body = body['ReceiveMessageResponse']['ReceiveMessageResult']
    #if no message retrun success false
    if body == None:
            return({'success':False})
    #otherwise continue
    body = body['Message']
    receipthandle = body['ReceiptHandle']
    #delete message from queue
    deletemessage(receipthandle)
    message = body['Body']
    #message = json.load(message)
    return({'success':True, 'message':message})
