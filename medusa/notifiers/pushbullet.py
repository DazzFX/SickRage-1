# -*- coding: utf-8 -*
# Author: Pedro Correia (http://github.com/pedrocorreia/)
# Based on pushalot.py by Nic Wolfe <nic@wolfeden.ca>
#
# This file is part of Medusa.
#
# Medusa is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Medusa is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Medusa. If not, see <http://www.gnu.org/licenses/>.

from __future__ import unicode_literals

import re

import medusa as app
from requests.compat import urljoin
from .. import common, helpers, logger


class Notifier(object):

    def __init__(self):
        self.session = helpers.make_session()
        self.url = 'https://api.pushbullet.com/v2/'

    def test_notify(self, pushbullet_api):
        logger.log('Sending a test Pushbullet notification.', logger.DEBUG)
        return self._sendPushbullet(
            pushbullet_api,
            event='Test',
            message='Testing Pushbullet settings from Medusa',
            force=True
        )

    def get_devices(self, pushbullet_api):
        logger.log('Testing Pushbullet authentication and retrieving the device list.', logger.DEBUG)
        headers = {'Access-Token': pushbullet_api}
        return helpers.getURL(urljoin(self.url, 'devices'), session=self.session, headers=headers, returns='text') or {}

    def notify_snatch(self, ep_name, is_proper):
        if app.PUSHBULLET_NOTIFY_ONSNATCH:
            self._sendPushbullet(
                pushbullet_api=None,
                event=common.notifyStrings[(common.NOTIFY_SNATCH, common.NOTIFY_SNATCH_PROPER)[is_proper]] + ' : ' + ep_name,
                message=ep_name
            )

    def notify_download(self, ep_name):
        if app.PUSHBULLET_NOTIFY_ONDOWNLOAD:
            self._sendPushbullet(
                pushbullet_api=None,
                event=common.notifyStrings[common.NOTIFY_DOWNLOAD] + ' : ' + ep_name,
                message=ep_name
            )

    def notify_subtitle_download(self, ep_name, lang):
        if app.PUSHBULLET_NOTIFY_ONSUBTITLEDOWNLOAD:
            self._sendPushbullet(
                pushbullet_api=None,
                event=common.notifyStrings[common.NOTIFY_SUBTITLE_DOWNLOAD] + ' : ' + ep_name + ' : ' + lang,
                message=ep_name + ': ' + lang
            )

    def notify_git_update(self, new_version='??'):
        link = re.match(r'.*href="(.*?)" .*', app.NEWEST_VERSION_STRING)
        if link:
            link = link.group(1)

        self._sendPushbullet(
            pushbullet_api=None,
            event=common.notifyStrings[common.NOTIFY_GIT_UPDATE],
            message=common.notifyStrings[common.NOTIFY_GIT_UPDATE_TEXT] + new_version,
            link=link
        )

    def notify_login(self, ipaddress=''):
        self._sendPushbullet(
            pushbullet_api=None,
            event=common.notifyStrings[common.NOTIFY_LOGIN],
            message=common.notifyStrings[common.NOTIFY_LOGIN_TEXT].format(ipaddress)
        )

    def _sendPushbullet(  # pylint: disable=too-many-arguments
            self, pushbullet_api=None, pushbullet_device=None, event=None, message=None, link=None, force=False):

        if not (app.USE_PUSHBULLET or force):
            return False

        pushbullet_api = pushbullet_api or app.PUSHBULLET_API
        pushbullet_device = pushbullet_device or app.PUSHBULLET_DEVICE

        logger.log('Pushbullet event: %r' % event, logger.DEBUG)
        logger.log('Pushbullet message: %r' % message, logger.DEBUG)
        logger.log('Pushbullet api: %r' % pushbullet_api, logger.DEBUG)
        logger.log('Pushbullet devices: %r' % pushbullet_device, logger.DEBUG)

        post_data = {
            'title': event,
            'body': message,
            'device_iden': pushbullet_device,
            'type': 'link' if link else 'note'
        }
        if link:
            post_data['url'] = link

        headers = {'Access-Token': pushbullet_api}

        response = helpers.getURL(urljoin(self.url, 'pushes'), session=self.session, post_data=post_data, headers=headers, returns='json') or {}
        if not response:
            return False

        failed = response.pop('error', {})
        if failed:
            logger.log('Pushbullet notification failed: {}'.format(failed.pop('message')), logger.WARNING)
        else:
            logger.log('Pushbullet notification sent.', logger.DEBUG)

        return False if failed else True
