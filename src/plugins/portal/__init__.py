# -*- coding: utf-8 -*-

__author__  = 'Fraser Molyneux'
__version__ = '1.0'

import b3
import b3.clients
import b3.events
import b3.plugin
import subprocess, sys
import requests
import json
from datetime import datetime

class PortalPlugin(b3.plugin.Plugin):

    adminPlugin = None
    requiresConfigFile = False

    _gameType = "Unknown"
    _serverId = ""
    _apimUrlBase = ""
    _tenantId = ""
    _clientId = ""
    _clientSecret = ""
    _apiSubscriptionKey = ""
    _scope = ""
    _pemFilePath = ""

## --- LOADCONFIG

    def onLoadConfig(self):
        self._gameType = self.getSetting('settings', 'gameType', b3.STR, self._gameType)
        self._serverId = self.getSetting('settings', 'serverId', b3.STR, self._serverId)
        self._apimUrlBase = self.getSetting('settings', 'apimUrlBase', b3.STR, self._apimUrlBase)
        self._tenantId = self.getSetting('settings', 'tenantId', b3.STR, self._tenantId)
        self._clientId = self.getSetting('settings', 'clientId', b3.STR, self._clientId)
        self._clientSecret = self.getSetting('settings', 'clientSecret', b3.STR, self._clientSecret)
        self._apiSubscriptionKey = self.getSetting('settings', 'apiSubscriptionKey', b3.STR, self._apiSubscriptionKey)
        self._scope = self.getSetting('settings', 'scope', b3.STR, self._scope)
        self._pemFilePath = self.getSetting('settings', 'pemFilePath', b3.STR, self._pemFilePath)

## --- PORTAL AUTH
    def generateAccessToken(self):
        data = {'grant_type': "client_credentials", 'scope': self._scope, 'client_id': self._clientId, 'client_secret': self._clientSecret}

        x = requests.post("https://login.microsoftonline.com/" + self._tenantId + "/oauth2/v2.0/token", data = data, verify=self._pemFilePath)
        tokenData = x.json()

        self.debug(tokenData)
        return tokenData['access_token']

## --- STARTUP

    def onStartup(self):
        """
        Initialize the plugin.
        """
        self.adminPlugin = self.console.getPlugin('admin')
        if not self.adminPlugin:
            raise AttributeError('could not get admin plugin')

        # register our commands
        self.adminPlugin.registerCommand(self, 'like', 1, self.cmd_like)
        self.adminPlugin.registerCommand(self, 'dislike', 1, self.cmd_dislike)

        # register events
        self.registerEvent('EVT_CLIENT_SAY', self.onSay)
        self.registerEvent('EVT_CLIENT_TEAM_SAY', self.onTeamSay)
        self.registerEvent('EVT_CLIENT_CONNECT', self.onConnect)

        url = self._apimUrlBase + '/OnServerConnected'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'Id': self._serverId,
            'gameType': self._gameType
        }
        
        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

## --- COMMANDS

    def cmd_like(self, data, client, _):
        url = self._apimUrlBase + '/OnMapVote'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'guid': event.client.guid,
            'mapName': self.console.game.mapName,
            'like': 'true'
        }
    
        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

        client.message("Thanks for your positive feedback - we have stored this in the map popularity database!")

    def cmd_dislike(self, data, client, _):
        url = self._apimUrlBase + '/OnMapVote'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'guid': event.client.guid,
            'mapName': self.console.game.mapName,
            'like': 'false'
        }
    
        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

        client.message("Thanks for your negative feedback - we have stored this in the map popularity database!")

## --- EVENTS

    def onSay(self, event):
        """
        Handle EVT_CLIENT_SAY
        """
        url = self._apimUrlBase + '/OnChatMessage'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'message': str(event.data),
            'type': 'All'
        }
    
        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

    def onTeamSay(self, event):
        """
        Handle EVT_CLIENT_TEAM_SAY
        """
        url = self._apimUrlBase + '/OnChatMessage'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'message': str(event.data),
            'type': 'Team'
        }

        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

    def onConnect(self, event):
        """
        Handle EVT_CLIENT_CONNECT
        """
        url = self._apimUrlBase + '/OnPlayerConnected'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'ipAddress': event.client.ip
        }

        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)

    def onMapChange(self, event):
        """
        Handle EVT_GAME_MAP_CHANGE
        """
        url = self._apimUrlBase + '/OnMapChange'
        token = self.generateAccessToken()

        headers = {
            'Content-Type': 'application/json',
            'Ocp-Apim-Subscription-Key': self._apiSubscriptionKey,
            'Authorization': 'Bearer ' + token
        }

        console = self.console.game

        gameName = ''
        gameType = ''
        mapName = ''

        if console.gameName:
            gameName = console.gameName
        if console.gameType:
            gameType = console.gameType
        if console.mapName:
            mapName = console.mapName

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'gameName': str(gameName),
            'mapName': str(mapName)
        }

        x = requests.post(url, json = eventData, headers = headers, verify=self._pemFilePath)