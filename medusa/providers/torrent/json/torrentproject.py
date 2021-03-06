# coding=utf-8
# Author: Gonçalo M. (aka duramato/supergonkas) <supergonkas@gmail.com>
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

import traceback
import validators

from ..TorrentProvider import TorrentProvider
from .... import logger, tvcache
from ....common import USER_AGENT
from ....helper.common import convert_size, try_int


class TorrentProjectProvider(TorrentProvider):  # pylint: disable=too-many-instance-attributes
    """TorrentProject Torrent provider"""
    def __init__(self):

        # Provider Init
        TorrentProvider.__init__(self, 'TorrentProject')

        # Credentials
        self.public = True

        # URLs
        self.url = 'https://torrentproject.se/'
        self.custom_url = None

        # Proper Strings

        # Miscellaneous Options
        self.headers.update({'User-Agent': USER_AGENT})

        # Torrent Stats
        self.minseed = None
        self.minleech = None

        # Cache
        self.cache = tvcache.TVCache(self, search_params={'RSS': ['0day']})

    def search(self, search_strings, age=0, ep_obj=None):  # pylint: disable=too-many-locals, too-many-branches
        """
        Search a provider and parse the results

        :param search_strings: A dict with mode (key) and the search value (value)
        :param age: Not used
        :param ep_obj: Not used
        :returns: A list of search results (structure)
        """
        results = []

        search_params = {
            'out': 'json',
            'filter': 2101,
            'showmagnets': 'on',
            'num': 150
        }

        for mode in search_strings:  # Mode = RSS, Season, Episode
            logger.log('Search mode: {0}'.format(mode), logger.DEBUG)

            for search_string in search_strings[mode]:
                if mode != 'RSS':
                    logger.log('Search string: {search}'.format
                               (search=search_string), logger.DEBUG)

                search_params['s'] = search_string

                if self.custom_url:
                    if not validators.url(self.custom_url):
                        logger.log('Invalid custom url set, please check your settings', logger.WARNING)
                        return results
                    search_url = self.custom_url
                else:
                    search_url = self.url

                response = self.get_url(search_url, params=search_params, returns='response')
                if not response or not response.content:
                    logger.log('No data returned from provider', logger.DEBUG)
                    continue

                try:
                    jdata = response.json()
                except ValueError:  # also catches JSONDecodeError if simplejson is installed
                    logger.log('No data returned from provider', logger.DEBUG)
                    continue

                results += self.parse(jdata, mode)

        return results

    def parse(self, data, mode):
        """
        Parse search results for items.

        :param data: The raw response from a search
        :param mode: The current mode used to search, e.g. RSS

        :return: A list of items found
        """

        items = []

        torrent_rows = data

        if not int(torrent_rows.pop('total_found', 0)) > 0:
            logger.log('Data returned from provider does not contain any torrents', logger.DEBUG)
            return items

        for row in torrent_rows:
            try:
                title = torrent_rows[row].get('title')
                download_url = torrent_rows[row].get('magnet')
                if not all([title, download_url]):
                    continue

                download_url += self._custom_trackers
                seeders = try_int(torrent_rows[row].get('seeds'), 1)
                leechers = try_int(torrent_rows[row].get('leechs'), 0)

                # Filter unseeded torrent
                if seeders < min(self.minseed, 1):
                    if mode != 'RSS':
                        logger.log("Discarding torrent because it doesn't meet the "
                                   "minimum seeders: {0}. Seeders: {1}".format
                                   (title, seeders), logger.DEBUG)
                    continue

                torrent_size = torrent_rows[row].get('torrent_size')
                size = convert_size(torrent_size) or -1
                torrent_hash = torrent_rows[row].get('torrent_hash')

                item = {
                    'title': title,
                    'link': download_url,
                    'size': size,
                    'seeders': seeders,
                    'leechers': leechers,
                    'pubdate': None,
                    'torrent_hash': torrent_hash,
                }
                if mode != 'RSS':
                    logger.log('Found result: {0} with {1} seeders and {2} leechers'.format
                               (title, seeders, leechers), logger.DEBUG)

                items.append(item)
            except (AttributeError, TypeError, KeyError, ValueError, IndexError):
                logger.log('Failed parsing provider. Traceback: {0!r}'.format
                           (traceback.format_exc()), logger.ERROR)

        return items


provider = TorrentProjectProvider()
