<%inherit file="/layouts/main.mako"/>
<%!
    import datetime
    import urllib
    import ntpath
    import medusa as app
    from medusa import subtitles, sbdatetime, network_timezones
    import medusa.helpers
    from medusa.common import SKIPPED, WANTED, UNAIRED, ARCHIVED, IGNORED, FAILED, DOWNLOADED
    from medusa.common import Quality, qualityPresets, statusStrings, Overview
    from medusa.helpers import anon_url
    from medusa.helper.common import pretty_file_size
%>
<%block name="scripts">
<script type="text/javascript" src="js/lib/jquery.bookmarkscroll.js?${sbPID}"></script>
<script type="text/javascript" src="js/plot-tooltip.js?${sbPID}"></script>
<script type="text/javascript" src="js/rating-tooltip.js?${sbPID}"></script>
<script type="text/javascript" src="js/ajax-episode-search.js?${sbPID}"></script>
<script type="text/javascript" src="js/ajax-episode-subtitles.js?${sbPID}"></script>
</%block>
<%block name="content">
<%namespace file="/inc_defs.mako" import="renderQualityPill"/>
    <div class="pull-left form-inline">
        Change Show:
        <div class="navShow"><img id="prevShow" src="images/prev.png" alt="&lt;&lt;" title="Prev Show" /></div>
            <select id="pickShow" class="form-control form-control-inline input-sm">
            % for curShowList in sortedShowLists:
                <% curShowType = curShowList[0] %>
                <% curShowList = curShowList[1] %>
                % if len(sortedShowLists) > 1:
                    <optgroup label="${curShowType}">
                % endif
                    % for curShow in curShowList:
                    <option value="${curShow.indexerid}" ${'selected="selected"' if curShow == show else ''}>${curShow.name}</option>
                    % endfor
                % if len(sortedShowLists) > 1:
                    </optgroup>
                % endif
            % endfor
            </select>
        <div class="navShow"><img id="nextShow" src="images/next.png" alt="&gt;&gt;" title="Next Show" /></div>
    </div>
    <div class="clearfix"></div>
    <div id="showtitle" data-showname="${show.name}">
        <h1 class="title" id="scene_exception_${show.indexerid}">${show.name}</h1>
    </div>
    % if seasonResults:
        ##There is a special/season_0?##
        % if int(seasonResults[-1]["season"]) == 0:
            <% season_special = 1 %>
        % else:
            <% season_special = 0 %>
        % endif
        % if not app.DISPLAY_SHOW_SPECIALS and season_special:
            <% lastSeason = seasonResults.pop(-1) %>
        % endif
        <span class="h2footer displayspecials pull-right">
            % if season_special:
            Display Specials:
                <a class="inner" href="home/toggleDisplayShowSpecials/?show=${show.indexerid}">${'Hide' if app.DISPLAY_SHOW_SPECIALS else 'Show'}</a>
            % endif
        </span>
        <div class="h2footer pull-right">
            <span>
            % if (len(seasonResults) > 14):
                <select id="seasonJump" class="form-control input-sm" style="position: relative; top: -4px;">
                    <option value="jump">Jump to Season</option>
                % for seasonNum in seasonResults:
                    <option value="#season-${seasonNum["season"]}" data-season="${seasonNum["season"]}">${'Season ' + str(seasonNum["season"]) if int(seasonNum["season"]) > 0 else 'Specials'}</option>
                % endfor
                </select>
            % else:
                Season:
                % for seasonNum in seasonResults:
                    % if int(seasonNum["season"]) == 0:
                        <a href="#season-${seasonNum["season"]}">Specials</a>
                    % else:
                        <a href="#season-${seasonNum["season"]}">${str(seasonNum["season"])}</a>
                    % endif
                    % if seasonNum != seasonResults[-1]:
                        <span class="separator">|</span>
                    % endif
                % endfor
            % endif
            </span>
        </div>
        % endif
    <div class="clearfix"></div>
% if show_message:
    <div class="alert alert-info">
        ${show_message}
    </div>
% endif
    <div id="container">
        <div id="posterCol">
            <a href="showPoster/?show=${show.indexerid}&amp;which=poster" rel="dialog" title="View Poster for ${show.name}"><img src="showPoster/?show=${show.indexerid}&amp;which=poster_thumb" class="tvshowImg" alt=""/></a>
        </div>
        <div id="showCol">

            <img id="showBanner" src="showPoster/?show=${show.indexerid}&amp;which=banner">

            <div id="showinfo">
% if 'rating' in show.imdb_info:
    <% rating_tip = str(show.imdb_info['rating']) + " / 10" + " Stars" + "<br>" + str(show.imdb_info['votes']) + " Votes" %>
    <span class="imdbstars" qtip-content="${rating_tip}">${show.imdb_info['rating']}</span>
% endif
% if not show.imdbid:
    <span>(${show.startyear}) - ${show.runtime} minutes - </span>
% else:
    % if 'country_codes' in show.imdb_info:
        % for country in show.imdb_info['country_codes'].split('|'):
                <img src="images/blank.png" class="country-flag flag-${country}" width="16" height="11" style="margin-left: 3px; vertical-align:middle;" />
        % endfor
    % endif
                <span>
    % if show.imdb_info.get('year'):
                    (${show.imdb_info['year']}) -
    % endif
                    ${show.imdb_info.get('runtimes') or show.runtime} minutes
                </span>
                <a href="${anon_url('http://www.imdb.com/title/', show.imdbid)}" rel="noreferrer" onclick="window.open(this.href, '_blank'); return false;" title="http://www.imdb.com/title/${show.imdbid}">
                    <img alt="[imdb]" height="16" width="16" src="images/imdb.png" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
% endif
                <a href="${anon_url(app.indexerApi(show.indexer).config['show_url'], show.indexerid)}" onclick="window.open(this.href, '_blank'); return false;" title="${app.indexerApi(show.indexer).config["show_url"] + str(show.indexerid)}">
                    <img alt="${app.indexerApi(show.indexer).name}" height="16" width="16" src="images/${app.indexerApi(show.indexer).config["icon"]}" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
% if xem_numbering or xem_absolute_numbering:
                <a href="${anon_url('http://thexem.de/search?q=', show.name)}" rel="noreferrer" onclick="window.open(this.href, '_blank'); return false;" title="http://thexem.de/search?q-${show.name}">
                    <img alt="[xem]" height="16" width="16" src="images/xem.png" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
% endif
                <a href="${anon_url('https://fanart.tv/series/', show.indexerid)}" rel="noreferrer" onclick="window.open(this.href, '_blank'); return false;" title="https://fanart.tv/series/${show.name}"><img alt="[fanart.tv]" height="16" width="16" src="images/fanart.tv.png" class="fanart"/></a>
            </div>
            <div id="tags">
                <ul class="tags">
                    % if show.imdb_info.get('genres'):
                        % for imdbgenre in show.imdb_info['genres'].replace('Sci-Fi','Science-Fiction').split('|'):
                            <a href="${anon_url('http://www.imdb.com/search/title?count=100&title_type=tv_series&genres=', imdbgenre.lower())}" target="_blank" title="View other popular ${imdbgenre} shows on IMDB."><li>${imdbgenre}</li></a>
                        % endfor
                    % elif show.genre:
                        % for genre in show.genre[1:-1].split('|'):
                            <a href="${anon_url('http://trakt.tv/shows/popular/?genres=', genre.lower())}" target="_blank" title="View other popular ${genre} shows on trakt.tv."><li>${genre}</li></a>
                        % endfor
                    % endif
                </ul>
            </div>

            <!-- Show Summary -->
            <div id="summary" ${'class="summaryFanArt"' if app.FANART_BACKGROUND else ''}>
                <table class="summaryTable pull-left">
                <% anyQualities, bestQualities = Quality.splitQuality(int(show.quality)) %>
                    <tr><td class="showLegend">Quality: </td><td>
                % if show.quality in qualityPresets:
                    ${renderQualityPill(show.quality)}
                % else:
                % if anyQualities:
                    <i>Allowed:</i> ${', '.join([capture(renderQualityPill, x) for x in sorted(anyQualities)])}${'<br>' if bestQualities else ''}
                % endif
                % if bestQualities:
                    <i>Preferred:</i> ${', '.join([capture(renderQualityPill, x) for x in sorted(bestQualities)])}
                % endif
                % endif
                % if show.network and show.airs:
                    <tr><td class="showLegend">Originally Airs: </td><td>${show.airs} ${"" if network_timezones.test_timeformat(show.airs) else "<font color='#FF0000'><b>(invalid Timeformat)</b></font>"} on ${show.network}</td></tr>
                % elif show.network:
                    <tr><td class="showLegend">Originally Airs: </td><td>${show.network}</td></tr>
                % elif show.airs:
                    <tr><td class="showLegend">Originally Airs: </td><td>${show.airs} ${"" if network_timezones.test_timeformat(show.airs) else "<font color='#FF0000'><b>(invalid Timeformat)</b></font>"}</td></tr>
                % endif
                    <tr><td class="showLegend">Show Status: </td><td>${show.status}</td></tr>
                    <tr><td class="showLegend">Default EP Status: </td><td>${statusStrings[show.default_ep_status]}</td></tr>
                % if showLoc[1]:
                    <tr><td class="showLegend">Location: </td><td>${showLoc[0]}</td></tr>
                % else:
                    <tr><td class="showLegend"><span style="color: rgb(255, 0, 0);">Location: </span></td><td><span style="color: rgb(255, 0, 0);">${showLoc[0]}</span> (Missing)</td></tr>
                % endif
                % if all_scene_exceptions:
                    <tr><td class="showLegend" style="vertical-align: top;">Scene Name:</td><td>${all_scene_exceptions}</td></tr>
                % endif
                % if require_words:
                    <tr><td class="showLegend" style="vertical-align: top;">Required Words: </td><td><span class="break-word">${require_words}</span></td></tr>
                % endif
                % if ignore_words:
                    <tr><td class="showLegend" style="vertical-align: top;">Ignored Words: </td><td><span class="break-word">${ignore_words}</span></td></tr>
                % endif
                % if preferred_words:
                    <tr><td class="showLegend" style="vertical-align: top;">Preferred Words: </td><td><span class="break-word">${preferred_words}</span></td></tr>
                % endif
                % if undesired_words:
                    <tr><td class="showLegend" style="vertical-align: top;">Undesired Words: </td><td><span class="break-word">${undesired_words}</span></td></tr>
                % endif
                % if bwl and bwl.whitelist:
                    <tr>
                        <td class="showLegend">Wanted Group${"s" if len(bwl.whitelist) > 1 else ""}:</td>
                        <td>${', '.join(bwl.whitelist)}</td>
                    </tr>
                % endif
                % if bwl and bwl.blacklist:
                    <tr>
                        <td class="showLegend">Unwanted Group${"s" if len(bwl.blacklist) > 1 else ""}:</td>
                        <td>${', '.join(bwl.blacklist)}</td>
                    </tr>
                % endif
                <tr><td class="showLegend">Size:</td><td>${pretty_file_size(app.helpers.get_size(showLoc[0]))}</td></tr>
                </table>

                <!-- Option table right -->
                <table class="showOptions">
                    <% info_flag = subtitles.code_from_code(show.lang) if show.lang else '' %>
                    <tr><td class="showLegend">Info Language:</td><td><img src="images/subtitles/flags/${info_flag}.png" width="16" height="11" alt="${show.lang}" title="${show.lang}" onError="this.onerror=null;this.src='images/flags/unknown.png';"/></td></tr>
                    % if app.USE_SUBTITLES:
                    <tr><td class="showLegend">Subtitles: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.subtitles)]}" alt="${("N", "Y")[bool(show.subtitles)]}" width="16" height="16" /></td></tr>
                    % endif
                    <tr><td class="showLegend">Season Folders: </td><td><img src="images/${("no16.png", "yes16.png")[bool(not show.flatten_folders or app.NAMING_FORCE_FOLDERS)]}" alt="${("N", "Y")[bool(not show.flatten_folders or app.NAMING_FORCE_FOLDERS)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">Paused: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.paused)]}" alt="${("N", "Y")[bool(show.paused)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">Air-by-Date: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.air_by_date)]}" alt="${("N", "Y")[bool(show.air_by_date)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">Sports: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.is_sports)]}" alt="${("N", "Y")[bool(show.is_sports)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">Anime: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.is_anime)]}" alt="${("N", "Y")[bool(show.is_anime)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">DVD Order: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.dvdorder)]}" alt="${("N", "Y")[bool(show.dvdorder)]}" width="16" height="16" /></td></tr>
                    <tr><td class="showLegend">Scene Numbering: </td><td><img src="images/${("no16.png", "yes16.png")[bool(show.scene)]}" alt="${("N", "Y")[bool(show.scene)]}" width="16" height="16" /></td></tr>
                </table>
            </div>
        </div>
    </div>
    <div class="clearfix"></div>
    <div class="pull-left" >
        Change selected episodes to:<br>
        <select id="statusSelect" class="form-control form-control-inline input-sm">
        <% availableStatus = [WANTED, SKIPPED, IGNORED, FAILED] %>
        % if not app.USE_FAILED_DOWNLOADS:
        <% availableStatus.remove(FAILED) %>
        % endif
        % for curStatus in availableStatus + Quality.DOWNLOADED + Quality.ARCHIVED:
            % if curStatus not in [DOWNLOADED, ARCHIVED]:
            <option value="${curStatus}">${statusStrings[curStatus]}</option>
            % endif
        % endfor
        </select>
        <input type="hidden" id="showID" value="${show.indexerid}" />
        <input type="hidden" id="indexer" value="${show.indexer}" />
        <input class="btn btn-inline" type="button" id="changeStatus" value="Go" />
    </div>
    <br>
    <div class="pull-right clearfix" id="checkboxControls">
        <div style="padding-bottom: 5px;">
            <% total_snatched = epCounts[Overview.SNATCHED] + epCounts[Overview.SNATCHED_PROPER] + epCounts[Overview.SNATCHED_BEST] %>
            <label for="wanted"><span class="wanted"><input type="checkbox" id="wanted" checked="checked" /> Wanted: <b>${epCounts[Overview.WANTED]}</b></span></label>
            <label for="qual"><span class="qual"><input type="checkbox" id="qual" checked="checked" /> Allowed: <b>${epCounts[Overview.QUAL]}</b></span></label>
            <label for="good"><span class="good"><input type="checkbox" id="good" checked="checked" /> Preferred: <b>${epCounts[Overview.GOOD]}</b></span></label>
            <label for="skipped"><span class="skipped"><input type="checkbox" id="skipped" checked="checked" /> Skipped: <b>${epCounts[Overview.SKIPPED]}</b></span></label>
            <label for="snatched"><span class="snatched"><input type="checkbox" id="snatched" checked="checked" /> Snatched: <b>${total_snatched}</b></span></label>
        </div>
        <button id="popover" type="button" class="btn btn-xs">Select Columns <b class="caret"></b></button>
        <div class="pull-right" >
            <button class="btn btn-xs seriesCheck">Select Filtered Episodes</button>
            <button class="btn btn-xs clearAll">Clear All</button>
        </div>
    </div>
<br>
<br>
<br>

<table id="${'animeTable' if show.is_anime else 'showTable'}" class="${'displayShowTableFanArt tablesorterFanArt' if app.FANART_BACKGROUND else 'displayShowTable'} display_show" cellspacing="0" border="0" cellpadding="0">
    <% curSeason = -1 %>
    <% odd = 0 %>
    <% epCount = 0 %>
    <% epSize = 0 %>
    <% epList = [] %>

    % for epResult in sql_results:
        <%
        epStr = str(epResult["season"]) + "x" + str(epResult["episode"])
        if not epStr in epCats:
            continue
        if not app.DISPLAY_SHOW_SPECIALS and int(epResult["season"]) == 0:
            continue
        scene = False
        scene_anime = False
        if not show.air_by_date and not show.is_sports and not show.is_anime and show.is_scene:
            scene = True
        elif not show.air_by_date and not show.is_sports and show.is_anime and show.is_scene:
            scene_anime = True
        (dfltSeas, dfltEpis, dfltAbsolute) = (0, 0, 0)
        if (epResult["season"], epResult["episode"]) in xem_numbering:
            (dfltSeas, dfltEpis) = xem_numbering[(epResult["season"], epResult["episode"])]
        if epResult["absolute_number"] in xem_absolute_numbering:
            dfltAbsolute = xem_absolute_numbering[epResult["absolute_number"]]
        if epResult["absolute_number"] in scene_absolute_numbering:
            scAbsolute = scene_absolute_numbering[epResult["absolute_number"]]
            dfltAbsNumbering = False
        else:
            scAbsolute = dfltAbsolute
            dfltAbsNumbering = True
        if (epResult["season"], epResult["episode"]) in scene_numbering:
            (scSeas, scEpis) = scene_numbering[(epResult["season"], epResult["episode"])]
            dfltEpNumbering = False
        else:
            (scSeas, scEpis) = (dfltSeas, dfltEpis)
            dfltEpNumbering = True
        epLoc = epResult["location"]
        if epLoc and show._location and epLoc.lower().startswith(show._location.lower()):
            epLoc = epLoc[len(show._location)+1:]
        %>
        % if int(epResult["season"]) != curSeason:
            % if curSeason == -1:
    <thead>
        <tr class="seasoncols" style="display:none;">
                <th data-sorter="false" data-priority="critical" class="col-checkbox"><input type="checkbox" class="seasonCheck"/></th>
                <th data-sorter="false" class="col-metadata">NFO</th>
                <th data-sorter="false" class="col-metadata">TBN</th>
                <th data-sorter="false" class="col-ep">Episode</th>
                <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(show.is_anime)]}>Absolute</th>
                <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene)]}>Scene</th>
                <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene_anime)]}>Scene Absolute</th>
                <th data-sorter="false" class="col-name">Name</th>
                <th data-sorter="false" class="col-name columnSelector-false">File Name</th>
                <th data-sorter="false" class="col-ep columnSelector-false">Size</th>
                <th data-sorter="false" class="col-airdate">Airdate</th>
                <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(app.DOWNLOAD_URL)]}>Download</th>
                <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(app.USE_SUBTITLES)]}>Subtitles</th>
                <th data-sorter="false" class="col-status">Status</th>
                <th data-sorter="false" class="col-search">Search</th>
        </tr>
    </thead>
    <tbody class="tablesorter-no-sort">
        <tr style="height: 60px;">
            <th class="row-seasonheader ${'displayShowTable' if app.FANART_BACKGROUND else 'displayShowTableFanArt'}" colspan="13" style="vertical-align: bottom; width: auto;">
                <h3 style="display: inline;"><a name="season-${epResult["season"]}"></a>${"Season " + str(epResult["season"]) if int(epResult["season"]) > 0 else "Specials"}
                <!-- @TODO: port the season scene exceptions to angular -->
                % if not any([i for i in sql_results if epResult['season'] == i['season'] and int(i['status']) == 1]):
                <a class="epManualSearch" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=1&amp;manual_search_type=season"><img data-ep-manual-search src="images/manualsearch${'-white' if app.THEME_NAME == 'dark' else ''}.png" width="16" height="16" alt="search" title="Manual Search" /></a>
                % endif
                </h3>
                <div class="season-scene-exception" data-season=${str(epResult["season"]) if int(epResult["season"]) > 0 else "Specials"}></div>
                % if app.DISPLAY_ALL_SEASONS is False:
                    <button id="showseason-${epResult['season']}" type="button" class="btn btn-xs pull-right" data-toggle="collapse" data-target="#collapseSeason-${epResult['season']}">Hide Episodes</button>
                % endif
            </th>
        </tr>
    </tbody>
    <tbody class="tablesorter-no-sort">
        <tr id="season-${epResult["season"]}-cols" class="seasoncols">
            <th class="col-checkbox"><input type="checkbox" class="seasonCheck" id="${epResult["season"]}" /></th>
            <th class="col-metadata">NFO</th>
            <th class="col-metadata">TBN</th>
            <th class="col-ep">Episode</th>
            <th class="col-ep">Absolute</th>
            <th class="col-ep">Scene</th>
            <th class="col-ep">Scene Absolute</th>
            <th class="col-name">Name</th>
            <th class="col-name">File Name</th>
            <th class="col-ep">Size</th>
            <th class="col-airdate">Airdate</th>
            <th class="col-ep">Download</th>
            <th class="col-ep">Subtitles</th>
            <th class="col-status">Status</th>
            <th class="col-search">Search</th>
        </tr>
            % else:
        <tr id="season-${epResult["season"]}-footer" class="seasoncols">
            <th class="col-footer" colspan=15 align=left>Season contains ${epCount} episodes with total filesize: ${pretty_file_size(epSize)}</th>
        </tr>
        <% epCount = 0 %>
        <% epSize = 0 %>
        <% epList = [] %>
    </tbody>
    <tbody class="tablesorter-no-sort">
        <tr style="height: 60px;">
            <th class="row-seasonheader ${'displayShowTableFanArt' if app.FANART_BACKGROUND else 'displayShowTable'}" colspan="13" style="vertical-align: bottom; width: auto;">
                <h3 style="display: inline;"><a name="season-${epResult["season"]}"></a>${"Season " + str(epResult["season"]) if int(epResult["season"]) else "Specials"}
                % if not any([i for i in sql_results if epResult['season'] == i['season'] and int(i['status']) == 1]):
                <a class="epManualSearch" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=1&amp;manual_search_type=season"><img data-ep-manual-search src="images/manualsearch${'-white' if app.THEME_NAME == 'dark' else ''}.png" width="16" height="16" alt="search" title="Manual Search" /></a>
                % endif
                </h3>
                <!-- @TODO: port the season scene exceptions to angular -->
                <div class="season-scene-exception" data-season=${str(epResult["season"])}></div>
                % if app.DISPLAY_ALL_SEASONS is False:
                    <button id="showseason-${epResult['season']}" type="button" class="btn btn-xs pull-right" data-toggle="collapse" data-target="#collapseSeason-${epResult['season']}">Show Episodes</button>
                % endif
            </th>
        </tr>
    </tbody>
    <tbody class="tablesorter-no-sort">
        <tr id="season-${epResult["season"]}-cols" class="seasoncols">
            <th class="col-checkbox"><input type="checkbox" class="seasonCheck" id="${epResult["season"]}" /></th>
            <th class="col-metadata">NFO</th>
            <th class="col-metadata">TBN</th>
            <th class="col-ep">Episode</th>
            <th class="col-ep">Absolute</th>
            <th class="col-ep">Scene</th>
            <th class="col-ep">Scene Absolute</th>
            <th class="col-name">Name</th>
            <th class="col-name">File Name</th>
            <th class="col-ep">Size</th>
            <th class="col-airdate">Airdate</th>
            <th class="col-ep">Download</th>
            <th class="col-ep">Subtitles</th>
            <th class="col-status">Status</th>
            <th class="col-search">Search</th>
        </tr>
            % endif
    </tbody>
        % if app.DISPLAY_ALL_SEASONS is False:
        <tbody class="toggle collapse${("", " in")[curSeason == -1]}" id="collapseSeason-${epResult['season']}">
        % else:
        <tbody>
        % endif
        <% curSeason = int(epResult["season"]) %>
        % endif
        <tr class="${Overview.overviewStrings[epCats[epStr]]} season-${curSeason} seasonstyle" id="${'S' + str(epResult["season"]) + 'E' + str(epResult["episode"])}">
            <td class="col-checkbox">
                % if int(epResult["status"]) != UNAIRED:
                    <input type="checkbox" class="epCheck" id="${str(epResult["season"])+'x'+str(epResult["episode"])}" name="${str(epResult["season"]) +"x"+str(epResult["episode"])}" />
                % endif
            </td>
            <td align="center"><img src="images/${("nfo-no.gif", "nfo.gif")[epResult["hasnfo"]]}" alt="${("N", "Y")[epResult["hasnfo"]]}" width="23" height="11" /></td>
            <td align="center"><img src="images/${("tbn-no.gif", "tbn.gif")[epResult["hastbn"]]}" alt="${("N", "Y")[epResult["hastbn"]]}" width="23" height="11" /></td>
            <td align="center">
            <%
                text = str(epResult['episode'])
                if epLoc != '' and epLoc is not None:
                    text = '<span title="' + epLoc + '" class="addQTip">' + text + "</span>"
                    epCount += 1
                    if not epLoc in epList:
                        epSize += epResult["file_size"]
                        epList.append(epLoc)
            %>
                ${text}
            </td>
            <td align="center">${epResult["absolute_number"]}</td>
            <td align="center">
                <input type="text" placeholder="${str(dfltSeas) + 'x' + str(dfltEpis)}" size="6" maxlength="8"
                    class="sceneSeasonXEpisode form-control input-scene" data-for-season="${epResult["season"]}" data-for-episode="${epResult["episode"]}"
                    id="sceneSeasonXEpisode_${show.indexerid}_${str(epResult["season"])}_${str(epResult["episode"])}"
                    title="Change this value if scene numbering differs from the indexer episode numbering. Generally used for non-anime shows."
                    % if dfltEpNumbering:
                        value=""
                    % else:
                        value="${str(scSeas)}x${str(scEpis)}"
                    % endif
                        style="padding: 0; text-align: center; max-width: 60px;"/>
            </td>
            <td align="center">
                <input type="text" placeholder="${str(dfltAbsolute)}" size="6" maxlength="8"
                    class="sceneAbsolute form-control input-scene" data-for-absolute="${epResult["absolute_number"]}"
                    id="sceneAbsolute_${show.indexerid}${"_"+str(epResult["absolute_number"])}"
                    title="Change this value if scene absolute numbering differs from the indexer absolute numbering. Generally used for anime shows."
                    % if dfltAbsNumbering:
                        value=""
                    % else:
                        value="${str(scAbsolute)}"
                    % endif
                        style="padding: 0; text-align: center; max-width: 60px;"/>
            </td>
            <td class="col-name">
            % if epResult["description"] != "" and epResult["description"] is not None:
                <img src="images/info32.png" width="16" height="16" class="plotInfo" alt="" id="plot_info_${str(show.indexerid)}_${str(epResult["season"])}_${str(epResult["episode"])}" />
            % else:
                <img src="images/info32.png" width="16" height="16" class="plotInfoNone" alt="" />
            % endif
            ${epResult["name"]}
            </td>
            <td class="col-name">${epLoc if Quality.splitCompositeStatus(int(epResult['status'])).status in [DOWNLOADED, ARCHIVED] else ''}</td>
            <td class="col-ep">
                % if epResult["file_size"] and Quality.splitCompositeStatus(int(epResult['status'])).status in [DOWNLOADED, ARCHIVED]:
                    ${pretty_file_size(epResult["file_size"])}
                % endif
            </td>
            <td class="col-airdate">
                % if int(epResult['airdate']) != 1:
                    ## Lets do this exactly like ComingEpisodes and History
                    ## Avoid issues with dateutil's _isdst on Windows but still provide air dates
                    <% airDate = datetime.datetime.fromordinal(epResult['airdate']) %>
                    % if airDate.year >= 1970 or show.network:
                        <% airDate = sbdatetime.sbdatetime.convert_to_setting(network_timezones.parse_date_time(epResult['airdate'], show.airs, show.network)) %>
                    % endif
                    <time datetime="${airDate.isoformat('T')}" class="date">${sbdatetime.sbdatetime.sbfdatetime(airDate)}</time>
                % else:
                    Never
                % endif
            </td>
            <td>
                % if app.DOWNLOAD_URL and epResult['location'] and Quality.splitCompositeStatus(int(epResult['status'])).status in [DOWNLOADED, ARCHIVED]:
                    <%
                        filename = epResult['location']
                        for rootDir in app.ROOT_DIRS.split('|'):
                            if rootDir.startswith('/'):
                                filename = filename.replace(rootDir, "")
                        filename = app.DOWNLOAD_URL + urllib.quote(filename.encode('utf8'))
                    %>
                    <center><a href="${filename}">Download</a></center>
                % endif
            </td>
            <td class="col-subtitles" align="center">
            % for flag in (epResult["subtitles"] or '').split(','):
                % if flag.strip() and Quality.splitCompositeStatus(int(epResult['status'])).status in [DOWNLOADED, ARCHIVED]:
                    <img src="images/subtitles/flags/${flag}.png" width="16" height="11" alt="${subtitles.name_from_code(flag)}" onError="this.onerror=null;this.src='images/flags/unknown.png';" />
                % endif
            % endfor
            </td>
                <% curStatus, curQuality = Quality.splitCompositeStatus(int(epResult["status"])) %>
                % if curQuality != Quality.NONE:
                    <td class="col-status">${statusStrings[curStatus]} ${renderQualityPill(curQuality)}</td>
                % else:
                    <td class="col-status">${statusStrings[curStatus]}</td>
                % endif
            <td class="col-search">
                % if int(epResult["season"]) != 0:
                    % if (int(epResult["status"]) in Quality.SNATCHED + Quality.SNATCHED_PROPER + Quality.SNATCHED_BEST + Quality.DOWNLOADED ) and app.USE_FAILED_DOWNLOADS:
                        <a class="epRetry" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/retryEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img data-ep-search src="images/search16.png" height="16" alt="retry" title="Retry Download" /></a>
                    % else:
                        <a class="epSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/searchEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img data-ep-search src="images/search16.png" width="16" height="16" alt="search" title="Forced Search" /></a>
                    % endif
                    <a class="epManualSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}&amp;manual_search_type=episode"><img data-ep-manual-search src="images/manualsearch.png" width="16" height="16" alt="search" title="Manual Search" /></a>
                % else:
                    <a class="epManualSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}&amp;manual_search_type=episode"><img data-ep-manual-search src="images/manualsearch.png" width="16" height="16" alt="search" title="Manual Search" /></a>
                % endif
                % if int(epResult["status"]) not in Quality.SNATCHED + Quality.SNATCHED_PROPER and app.USE_SUBTITLES and show.subtitles and epResult["location"] and subtitles.needs_subtitles(epResult['subtitles']):
                    <a class="epSubtitlesSearch" href="home/searchEpisodeSubtitles?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img src="images/closed_captioning.png" height="16" alt="search subtitles" title="Search Subtitles" /></a>
                % endif
            </td>
        </tr>
    % endfor
        <tr id="season-${epResult["season"]}-footer" class="seasoncols">
            <th class="col-footer" colspan=15 align=left>Season contains ${epCount} episodes with total filesize: ${pretty_file_size(epSize)}</th>
        </tr>
    </tbody>
</table>
<!--Begin - Bootstrap Modal-->
<div id="forcedSearchModalFailed" class="modal fade">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h4 class="modal-title">Forced Search</h4>
            </div>
            <div class="modal-body">
                <p>Do you want to mark this episode as failed?</p>
                <p class="text-warning"><small>The episode release name will be added to the failed history, preventing it to be downloaded again.</small></p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-danger" data-dismiss="modal">No</button>
                <button type="button" class="btn btn-success" data-dismiss="modal">Yes</button>
            </div>
        </div>
    </div>
</div>
<div id="forcedSearchModalQuality" class="modal fade">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h4 class="modal-title">Forced Search</h4>
            </div>
            <div class="modal-body">
                <p>Do you want to include the current episode quality in the search?</p>
                <p class="text-warning"><small>Choosing No will ignore any releases with the same episode quality as the one currently downloaded/snatched.</small></p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-danger" data-dismiss="modal">No</button>
                <button type="button" class="btn btn-success" data-dismiss="modal">Yes</button>
            </div>
        </div>
    </div>
</div>
<!--End - Bootstrap Modal-->
</%block>
