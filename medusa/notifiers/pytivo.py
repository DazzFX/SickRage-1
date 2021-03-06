# coding=utf-8

# Author: Nic Wolfe <nic@wolfeden.ca>
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

import os

import medusa as app
from requests.compat import urlencode
from six.moves.urllib.error import HTTPError
from six.moves.urllib.request import Request, urlopen
from .. import logger
from ..helper.encoding import ek
from ..helper.exceptions import ex


class Notifier(object):
    def notify_snatch(self, ep_name, is_proper):
        pass

    def notify_download(self, ep_name):
        pass

    def notify_subtitle_download(self, ep_name, lang):
        pass

    def notify_git_update(self, new_version):
        pass

    def notify_login(self, ipaddress=""):
        pass

    def update_library(self, ep_obj):

        # Values from config

        if not app.USE_PYTIVO:
            return False

        host = app.PYTIVO_HOST
        shareName = app.PYTIVO_SHARE_NAME
        tsn = app.PYTIVO_TIVO_NAME

        # There are two more values required, the container and file.
        #
        # container: The share name, show name and season
        #
        # file: The file name
        #
        # Some slicing and dicing of variables is required to get at these values.
        #
        # There might be better ways to arrive at the values, but this is the best I have been able to
        # come up with.
        #

        # Calculated values
        showPath = ep_obj.show.location
        showName = ep_obj.show.name
        rootShowAndSeason = ek(os.path.dirname, ep_obj.location)
        absPath = ep_obj.location

        # Some show names have colons in them which are illegal in a path location, so strip them out.
        # (Are there other characters?)
        showName = showName.replace(":", "")

        root = showPath.replace(showName, "")
        showAndSeason = rootShowAndSeason.replace(root, "")

        container = shareName + "/" + showAndSeason
        filename = "/" + absPath.replace(root, "")

        # Finally create the url and make request
        requestUrl = "http://" + host + "/TiVoConnect?" + urlencode(
            {'Command': 'Push', 'Container': container, 'File': filename, 'tsn': tsn})

        logger.log(u"pyTivo notification: Requesting " + requestUrl, logger.DEBUG)

        request = Request(requestUrl)

        try:
            urlopen(request)
        except HTTPError as e:
            if hasattr(e, 'reason'):
                logger.log(u"pyTivo notification: Error, failed to reach a server - " + e.reason, logger.ERROR)
                return False
            elif hasattr(e, 'code'):
                logger.log(u"pyTivo notification: Error, the server couldn't fulfill the request - " + e.code, logger.ERROR)
            return False
        except Exception as e:
            logger.log(u"PYTIVO: Unknown exception: " + ex(e), logger.ERROR)
            return False
        else:
            logger.log(u"pyTivo notification: Successfully requested transfer of file")
            return True
