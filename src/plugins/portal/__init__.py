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
import os
import tempfile
from datetime import datetime, timedelta
from requests.adapters import HTTPAdapter
try:
    from urllib3.util import Retry
except ImportError:
    # Older environments may vendor urllib3 under requests
    from requests.packages.urllib3.util import Retry


class PortalPlugin(b3.plugin.Plugin):

    adminPlugin = None
    requiresConfigFile = False

    _gameType = "Unknown"
    _serverId = ""
    _apimUrlBase = ""
    _tenantId = ""
    _clientId = ""
    _clientSecret = ""
    _scope = ""
    _pemFilePath = ""
    _spoolPath = ""
    _session = None
    _accessToken = None
    _accessTokenExpiryUtc = None
    _spool = None

## --- LOADCONFIG

    def onLoadConfig(self):
        self._gameType = self.getSetting('settings', 'gameType', b3.STR, self._gameType)
        self._serverId = self.getSetting('settings', 'serverId', b3.STR, self._serverId)
        self._apimUrlBase = self.getSetting('settings', 'apimUrlBase', b3.STR, self._apimUrlBase)
        self._tenantId = self.getSetting('settings', 'tenantId', b3.STR, self._tenantId)
        self._clientId = self.getSetting('settings', 'clientId', b3.STR, self._clientId)
        self._clientSecret = self.getSetting('settings', 'clientSecret', b3.STR, self._clientSecret)
        self._scope = self.getSetting('settings', 'scope', b3.STR, self._scope)
        self._pemFilePath = self.getSetting('settings', 'pemFilePath', b3.STR, self._pemFilePath)

        self._spoolPath = self.getSetting('settings', 'spoolPath', b3.STR, self._spoolPath)
        if not self._spoolPath:
            self.error('spoolPath must be configured for portal plugin; offline queue will be disabled')

        if not self._apimUrlBase or not self._tenantId or not self._clientId or not self._clientSecret:
            self.error('Portal plugin configuration is missing required settings; outbound calls will fail until fixed')

## --- PORTAL AUTH
    def generateAccessToken(self):
        if self._session is None:
            self._setupSession()

        if self._accessToken and self._accessTokenExpiryUtc and datetime.utcnow() < (self._accessTokenExpiryUtc - timedelta(seconds=60)):
            return self._accessToken

        data = {
            'grant_type': "client_credentials",
            'scope': self._scope,
            'client_id': self._clientId,
            'client_secret': self._clientSecret
        }

        try:
            response = self._session.post(
                "https://login.microsoftonline.com/" + self._tenantId + "/oauth2/v2.0/token",
                data=data,
                verify=self._pemFilePath,
                timeout=5
            )
            response.raise_for_status()
            tokenData = response.json()
            self._accessToken = tokenData.get('access_token')
            expires_in = tokenData.get('expires_in', 0)
            if self._accessToken and expires_in:
                self._accessTokenExpiryUtc = datetime.utcnow() + timedelta(seconds=int(expires_in))
            else:
                self._accessTokenExpiryUtc = None
            return self._accessToken
        except Exception as e:
            self.error('Failed to acquire access token: %s' % e)
            return None

## --- STARTUP

    def onStartup(self):
        """
        Initialize the plugin.
        """
        self._setupSession()
        self._loadSpool()

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
        self.registerEvent('EVT_GAME_MAP_CHANGE', self.onMapChange)

        url = self._apimUrlBase + '/OnServerConnected'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'Id': self._serverId,
            'gameType': self._gameType
        }

        self._postEvent(url, eventData, headers)
        self._drainSpool()

## --- COMMANDS

    def cmd_like(self, data, client, _):
        url = self._apimUrlBase + '/OnMapVote'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'guid': client.guid,
            'mapName': self.console.game.mapName,
            'like': 'true'
        }
        self._postEvent(url, eventData, headers)

        client.message("Thanks for your positive feedback - we have stored this in the map popularity database!")

    def cmd_dislike(self, data, client, _):
        url = self._apimUrlBase + '/OnMapVote'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'guid': client.guid,
            'mapName': self.console.game.mapName,
            'like': 'false'
        }
        self._postEvent(url, eventData, headers)

        client.message("Thanks for your negative feedback - we have stored this in the map popularity database!")

## --- EVENTS

    def onSay(self, event):
        """
        Handle EVT_CLIENT_SAY
        """
        url = self._apimUrlBase + '/OnChatMessage'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'message': str(event.data),
            'type': 'All'
        }

        self._postEvent(url, eventData, headers)

    def onTeamSay(self, event):
        """
        Handle EVT_CLIENT_TEAM_SAY
        """
        url = self._apimUrlBase + '/OnChatMessage'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'message': str(event.data),
            'type': 'Team'
        }

        self._postEvent(url, eventData, headers)

    def onConnect(self, event):
        """
        Handle EVT_CLIENT_CONNECT
        """
        url = self._apimUrlBase + '/OnPlayerConnected'
        headers = self._defaultHeaders()

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'username': str(event.client.name),
            'guid': event.client.guid,
            'ipAddress': event.client.ip
        }

        self._postEvent(url, eventData, headers)

    def onMapChange(self, event):
        """
        Handle EVT_GAME_MAP_CHANGE
        """
        url = self._apimUrlBase + '/OnMapChange'
        headers = self._defaultHeaders()

        console = self.console.game

        gameName = console.gameName if console.gameName else ''
        gameType = console.gameType if console.gameType else ''
        mapName = console.mapName if console.mapName else ''

        eventData = {
            'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
            'gameType': self._gameType,
            'serverId': self._serverId,
            'gameName': str(gameName),
            'mapName': str(mapName)
        }

        self._postEvent(url, eventData, headers)

## --- INTERNAL

    def _setupSession(self):
        self._session = requests.Session()
        retry_kwargs = {
            'total': 3,
            'backoff_factor': 0.5,
            'status_forcelist': [429, 500, 502, 503, 504]
        }

        try:
            retry = Retry(allowed_methods=["POST"], raise_on_status=False, **retry_kwargs)
        except TypeError:
            retry = Retry(method_whitelist=["POST"], **retry_kwargs)
        adapter = HTTPAdapter(max_retries=retry)
        self._session.mount('https://', adapter)
        self._session.mount('http://', adapter)

    def _postEvent(self, url, payload, headers):
        if headers is None:
            headers = self._defaultHeaders()

        if not headers.get('Authorization'):
            token = self.generateAccessToken()
            if not token:
                self._enqueueSpool(url, payload)
                return
            headers['Authorization'] = 'Bearer ' + token

        try:
            response = self._session.post(url, json=payload, headers=headers, verify=self._pemFilePath, timeout=5)
            if not response.ok:
                self.warning('Portal API returned %s for %s' % (response.status_code, url))
                self._enqueueSpool(url, payload)
        except Exception as e:
            self.warning('Portal API call failed: %s' % e)
            self._enqueueSpool(url, payload)

    def _enqueueSpool(self, url, payload):
        if self._spool is None:
            self._spool = []
        record = {'url': url, 'payload': payload}
        self._spool.append(record)
        try:
            with open(self._spoolPath, 'a') as f:
                f.write(json.dumps(record) + "\n")
        except Exception as e:
            self.error('Failed to write spool file %s: %s' % (self._spoolPath, e))

    def _loadSpool(self):
        self._spool = []
        if not os.path.isfile(self._spoolPath):
            return
        try:
            with open(self._spoolPath, 'r') as f:
                for line in f:
                    try:
                        self._spool.append(json.loads(line))
                    except ValueError:
                        continue
        except Exception as e:
            self.error('Failed to read spool file %s: %s' % (self._spoolPath, e))

    def _drainSpool(self):
        if not self._spool:
            return
        remaining = []
        headers = self._defaultHeaders()
        for record in self._spool:
            try:
                response = self._session.post(
                    record.get('url'),
                    json=record.get('payload'),
                    headers=headers,
                    verify=self._pemFilePath,
                    timeout=5
                )
                if not response.ok:
                    remaining.append(record)
            except Exception:
                remaining.append(record)
        self._spool = remaining
        try:
            with open(self._spoolPath, 'w') as f:
                for record in self._spool:
                    f.write(json.dumps(record) + "\n")
        except Exception as e:
            self.error('Failed to rewrite spool file %s: %s' % (self._spoolPath, e))

    def _defaultHeaders(self):
        token = self.generateAccessToken()
        return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token if token else ''
        }
