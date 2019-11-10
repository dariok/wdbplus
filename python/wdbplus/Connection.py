'''
Created on 5 Nov 2019

@author: dario
'''
import os
import requests
import mimetypes

class Connection(object):
    '''
    classdocs
    '''


    def __init__(self, serverUrl):
        self.serverUrl = serverUrl
        self.data = []
        self.result = []
    
    def login( self, loginUrl, user, pwd, session ):
        loginData = {
            "user": user,
            "password": pwd
        }
        return session.post(self.serverUrl + '/' + loginUrl, loginData)
    
    def setData(self, path):
        mime = mimetypes.guess_type(path)
        data = open(path, "rb")
        self.data = {"file": (path, data, mime)}
    
    def post (self, endpoint, data, file):
        self.result = requests.post(url = self.serverUrl + '/' + endpoint, auth = (self.user, self.password),
                               files = file, data = data)
    
    def put (self, endpoint, data, file):
        self.result = requests.put(url = self.serverUrl + '/' + endpoint, auth = (self.user, self.password),
                               files = file, data = data)
    
    def get (self, endpoint, data, file):
        self.result = requests.get(url = self.serverUrl + '/' + endpoint, auth = (self.user, self.password),
                               files = file, data = data)   
    