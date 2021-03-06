# coding=utf-8
# # Author: Mr_Orange
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

import io
import os
import re

from bencode import bdecode
import medusa as app
from ..TorrentProvider import TorrentProvider
from .... import helpers, logger, tvcache
from ....helper.encoding import ek
from ....helper.exceptions import ex


class TorrentRssProvider(TorrentProvider):  # pylint: disable=too-many-instance-attributes

    def __init__(self, name, url, cookies='',  # pylint: disable=too-many-arguments
                 titleTAG='title', search_mode='eponly', search_fallback=False,
                 enable_daily=False, enable_backlog=False, enable_manualsearch=False):

        # Provider Init
        TorrentProvider.__init__(self, name)

        # Credentials

        # URLs
        self.url = url.rstrip('/')

        # Proper Strings

        # Miscellaneous Options
        self.supports_backlog = False
        self.search_mode = search_mode
        self.search_fallback = search_fallback
        self.enable_daily = enable_daily
        self.enable_manualsearch = enable_manualsearch
        self.enable_backlog = enable_backlog
        self.enable_cookies = True
        self.cookies = cookies
        self.titleTAG = titleTAG

        # Torrent Stats

        # Cache
        self.cache = TorrentRssCache(self, min_time=15)

    def _get_title_and_url(self, item):

        title = item.get(self.titleTAG, '').replace(' ', '.')

        attempt_list = [
            lambda: item.get('torrent_magneturi'),
            lambda: item.enclosures[0].href,
            lambda: item.get('link')
        ]

        url = None
        for cur_attempt in attempt_list:
            try:
                url = cur_attempt()
            except Exception:
                continue

            if title and url:
                break

        return title, url

    def config_string(self):  # pylint: disable=too-many-arguments
        return '{}|{}|{}|{}|{}|{}|{}|{}|{}|{}'.format(
            self.name or '',
            self.url or '',
            self.cookies or '',
            self.titleTAG or '',
            int(self.enabled),
            self.search_mode or '',
            int(self.search_fallback),
            int(self.enable_daily),
            int(self.enable_manualsearch),
            int(self.enable_backlog)
        )

    @staticmethod
    def get_providers_list(data):
        providers_list = [x for x in (TorrentRssProvider._make_provider(x) for x in data.split('!!!')) if x]
        seen_values = set()
        providers_set = []

        for provider in providers_list:
            value = provider.name

            if value not in seen_values:
                providers_set.append(provider)
                seen_values.add(value)

        return [x for x in providers_set if x]

    def image_name(self):
        if ek(os.path.isfile, ek(os.path.join, app.PROG_DIR, 'gui', app.GUI_NAME, 'images', 'providers', self.get_id() + '.png')):
            return self.get_id() + '.png'
        return 'torrentrss.png'

    @staticmethod
    def _make_provider(config):
        if not config:
            return None

        cookies = ''
        enable_backlog = 0
        enable_daily = 0
        enable_manualsearch = 0
        search_fallback = 0
        search_mode = 'eponly'
        title_tag = 'title'

        try:
            values = config.split('|')

            if len(values) == 9:
                name, url, cookies, title_tag, enabled, search_mode, search_fallback, enable_daily, enable_backlog = values
            elif len(values) == 10:
                name, url, cookies, title_tag, enabled, search_mode, search_fallback, enable_daily, enable_backlog, enable_manualsearch = values
            elif len(values) == 8:
                name, url, cookies, enabled, search_mode, search_fallback, enable_daily, enable_backlog = values
            else:
                enabled = values[4]
                name = values[0]
                url = values[1]
        except ValueError:
            logger.log('Skipping RSS Torrent provider string: {}, incorrect format'.format(config), logger.ERROR)
            return None

        new_provider = TorrentRssProvider(
            name, url, cookies=cookies, titleTAG=title_tag, search_mode=search_mode, search_fallback=search_fallback,
            enable_daily=enable_daily, enable_backlog=enable_backlog, enable_manualsearch=enable_manualsearch
        )
        new_provider.enabled = enabled == '1'

        return new_provider

    def validate_rss(self):  # pylint: disable=too-many-return-statements

        try:
            add_cookie = self.add_cookies_from_ui()
            if not add_cookie.get('result'):
                return add_cookie

            # pylint: disable=protected-access
            # Access to a protected member of a client class
            data = self.cache._getRSSData()['entries']
            if not data:
                return {'result': False,
                        'message': 'No items found in the RSS feed {0}'.format(self.url)}

            title, url = self._get_title_and_url(data[0])

            if not title:
                return {'result': False,
                        'message': 'Unable to get title from first item'}

            if not url:
                return {'result': False,
                        'message': 'Unable to get torrent url from first item'}

            if url.startswith('magnet:') and re.search(r'urn:btih:([\w]{32,40})', url):
                return {'result': True,
                        'message': 'RSS feed Parsed correctly'}
            else:
                torrent_file = self.get_url(url, returns='content')
                try:
                    bdecode(torrent_file)
                except Exception as error:
                    self.dump_html(torrent_file)
                    return {'result': False,
                            'message': 'Torrent link is not a valid torrent file: {0}'.format(ex(error))}

            return {'result': True, 'message': 'RSS feed Parsed correctly'}

        except Exception as error:
            return {'result': False, 'message': 'Error when trying to load RSS: {0}'.format(ex(error))}

    @staticmethod
    def dump_html(data):
        dump_name = ek(os.path.join, app.CACHE_DIR, 'custom_torrent.html')

        try:
            file_out = io.open(dump_name, 'wb')
            file_out.write(data)
            file_out.close()
            helpers.chmodAsParent(dump_name)
        except IOError as error:
            logger.log('Unable to save the file: {0}'.format(ex(error)), logger.ERROR)
            return False

        logger.log('Saved custom_torrent html dump {0} '.format(dump_name), logger.INFO)
        return True


class TorrentRssCache(tvcache.TVCache):
    def _getRSSData(self):
        self.provider.add_cookies_from_ui()
        return self.getRSSFeed(self.provider.url)
