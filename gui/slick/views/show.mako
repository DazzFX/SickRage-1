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
<script src="https://unpkg.com/vue@2.0.1/dist/vue.js"></script>
<script src="https://unpkg.com/axios@0.12.0/dist/axios.min.js"></script>
<script src="https://unpkg.com/lodash@4.13.1/lodash.min.js"></script>
<script>
var app;
var startVue = function(){
    app = new Vue({
        el: '#vue-wrap',
        data: {
            show: {},
            shows: {},
            MEDUSA: MEDUSA,
            statuses: {
                UNKNOWN: -1,
                UNAIRED: 1,
                SNATCHED: 2,
                WANTED: 3,
                DOWNLOADED: 4,
                SKIPPED: 5,
                ARCHIVED: 6,
                IGNORED: 7,
                SNATCHED_PROPER: 9,
                SUBTITLED: 10,
                FAILED: 11,
                SNATCHED_BEST: 12
            }
        },
        methods: {
            getShow: function() {
                var vm = this;
                axios.get('/api/v2/show/' + parseInt(document.location.search.split('show=')[1], 10) + '?api_key=' + apiKey).then(function(response) {
                    vm.show = response.data.shows[0];
                    vm.show.seasons.reverse().forEach(function(season){
                        season.episodes.reverse();
                    });
                    vm.getShows();
                }).catch(function (error) {
                    throw new Error(error);
                });
            },
            getShows: function() {
                var vm = this;
                axios.get('/api/v2/show?api_key=' + apiKey).then(function(response) {
                    vm.shows = response.data.shows;
                }).catch(function (error) {
                    throw new Error(error);
                });
            },
            anonRedirect: function(e) {
                e.preventDefault();
                var url = e.target.nodeName === 'IMG' ? e.target.parentElement.href : e.target.href;
                window.open(MEDUSA.info.anonRedirect + url, '_blank');
            },
            prettyFileSize: function(bytes) {
                // http://stackoverflow.com/a/14919494/2311366
                if(Math.abs(bytes) < 1024) {
                    return bytes + ' B';
                }
                var units = ['kB','MB','GB','TB','PB','EB','ZB','YB'];
                var u = -1;
                do {
                    bytes /= 1024;
                    ++u;
                } while(Math.abs(bytes) >= 1024 && u < units.length - 1);
                return bytes.toFixed(1) + ' ' + units[u];
            }
        },
        mounted: function () {
            this.$nextTick(function() {
                // this.$el is in-document
                this.getShow();
            });
        }
    });
};
</script>
</%block>
<%block name="content">
<div v-cloak v-if="Object.keys(show).length">
<%namespace file="/inc_defs.mako" import="renderQualityPill"/>
    <div class="pull-left form-inline">
        Change Show:
        <div class="navShow"><img id="prevShow" src="images/prev.png" alt="&lt;&lt;" title="Prev Show" /></div>
        <select id="pickShow" class="form-control form-control-inline input-sm">
            <option v-for="show in shows" v-bind:value="show.ids.thetvdb" v-bind:selected="show.ids.thetvdb === $root.show.ids.thetvdb ? 'selected' : ''">{{show.name}}</option>
        </select>
        <div class="navShow"><img id="nextShow" src="images/next.png" alt="&gt;&gt;" title="Next Show" /></div>
    </div>
    <div class="clearfix"></div>
    <div id="showtitle">
        <h1 class="title">{{show.name}}</h1>
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
            <a v-bind:href="'showPoster/?show=' + show.ids.thetvdb + '&amp;which=poster'" rel="dialog" v-bind:title="'View Poster for ' + show.name">
                <img v-bind:src="'showPoster/?show=' + show.ids.thetvdb + '&amp;which=poster_thumb'" class="tvshowImg" v-bind:alt="'Poster Thumbnail for ' + show.name"/>
            </a>
        </div>
        <div id="showCol">
            <img id="showBanner" v-bind:src="'showPoster/?show=' + show.ids.thetvdb + '&amp;which=banner'">
            <div id="showinfo">
                <span v-if="show.ratings.imdb" class="imdbstars" v-bind:qtip-content="show.ratings.imdb.stars + ' / 10 Stars<br>' + show.ratings.imdb.votes + ' Votes'">{{show.ratings.imdb.stars}}</span>
                <img v-if="show.ratings.imdb" v-for="country in show.countries" src="images/blank.png" v-bind:class="'country-flag flag-' + country" width="16" height="11" style="margin-left: 3px; vertical-align:middle;" />
                <span>({{show.startYear}}) - {{show.runtime}} minutes - </span>
                <a v-bind:href="'https://www.imdb.com/title/' + show.ids.imdb" rel="noreferrer" v-on:click="anonRedirect" v-bind:title="'https://www.imdb.com/title/' + show.ids.imdb">
                    <img alt="[imdb]" height="16" width="16" src="images/imdb.png" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
                <a v-bind:href="'http://thetvdb.com/?tab=series&id=' + show.ids.thetvdb" v-bind:title="'http://thetvdb.com/?tab=series&id=' + show.ids.thetvdb">
                    <img alt="[thetvdb]" height="16" width="16" src="images/thetvdb.png" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
% if xem_numbering or xem_absolute_numbering:
                <a href="${anon_url('http://thexem.de/search?q=', show.name)}" rel="noreferrer" onclick="window.open(this.href, '_blank'); return false;" title="http://thexem.de/search?q-${show.name}">
                    <img alt="[xem]" height="16" width="16" src="images/xem.png" style="margin-top: -1px; vertical-align:middle;"/>
                </a>
% endif
                <a v-bind:href="'https://fanart.tv/series/' + show.ids.imdbid" v-bind:title="'https://fanart.tv/series/' + show.ids.imdbid">
                    <img alt="[fanart.tv]" height="16" width="16" src="images/fanart.tv.png" class="fanart"/>
                </a>
            </div>
            <div v-if="show.genres" id="tags">
                <ul v-for="genre in show.genres" class="tags">
                    <a v-if="show.ids.imdb" v-bind:href="'http://www.imdb.com/search/title?count=100&title_type=tv_series&genres=' + genre.toLowerCase().replace('Sci-Fi', 'Science-Fiction')" v-bind:title="'View other popular ' + genre + 'shows on IMDB.'"><li>{{genre}}</li></a>
                    <a v-if="!show.ids.imdb" v-bind:href="'http://trakt.tv/shows/popular/?genres=' + genre.toLowerCase()" target="_blank" v-bind:title="'View other popular ' + genre + 'shows on trakt.tv.'"><li>{{genre}}</li></a>
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

<table v-bind:id="show.anime ? 'animeTable' : 'showTable'" v-bind:class="(MEDUSA.info.fanartBackground ? 'displayShowTableFanArt tablesorterFanArt' : 'displayShowTable') + 'display_show'" cellspacing="0" border="0" cellpadding="0">
    <tbody v-for="season in show.seasons" v-bind:class="MEDUSA.info.displayAllSeasons ? '' : 'toggle collapse' + (season.seasonNumber === -1 ? ' in' : '')" v-bind:id="MEDUSA.info.displayAllSeasons ? '' : 'collapseSeason-' + season.seasonNumber">
        ## @TODO: Overview needs to be converted to a js function or an API field on the show/season/episode property
        ## <tr class="${Overview.overviewStrings[epCats[epStr]]}">
        <tr v-for="episode in season.episodes" v-bind:class="'season-' + season.seasonNumber + ' seasonstyle'" v-bind:id="'S' + season.seasonNumber + 'E' + episode.episodeNumber">
            <td class="col-checkbox">
                <input v-if="episode.status.raw !== statuses.UNAIRED" type="checkbox" class="epCheck" v-bind:id="season.seasonNumber + 'x' + episode.episodeNumber" name="season.seasonNumber + 'x' + episode.episodeNumber" />
            </td>
            <td align="center"><img v-bind:src="'images/nfo' + (episode.hasnfo ? '' : '-no') + '.gif'" v-bind:alt="episode.hasnfo ? 'Y' : 'N'" width="23" height="11" /></td>
            <td align="center"><img v-bind:src="'images/tbn' + (episode.hastbn ? '' : '-no') + '.gif'" v-bind:alt="episode.hastbn ? 'Y' : 'N'" width="23" height="11" /></td>
            ## <td align="center">
            ## <%
            ##     text = str(epResult['episode'])
            ##     if epLoc != '' and epLoc is not None:
            ##         text = '<span title="' + epLoc + '" class="addQTip">' + text + "</span>"
            ##         epCount += 1
            ##         if not epLoc in epList:
            ##             epSize += epResult["file_size"]
            ##             epList.append(epLoc)
            ## %>
            ##     ${text}
            ## </td>
            <td align="center">{{episode.absoluteNumber}}</td>
            ## <td align="center">
            ##     <input type="text" placeholder="${str(dfltSeas) + 'x' + str(dfltEpis)}" size="6" maxlength="8"
            ##         class="sceneSeasonXEpisode form-control input-scene" data-for-season="${epResult["season"]}" data-for-episode="${epResult["episode"]}"
            ##         id="sceneSeasonXEpisode_${show.indexerid}_${str(epResult["season"])}_${str(epResult["episode"])}"
            ##         title="Change this value if scene numbering differs from the indexer episode numbering. Generally used for non-anime shows."
            ##         % if dfltEpNumbering:
            ##             value=""
            ##         % else:
            ##             value="${str(scSeas)}x${str(scEpis)}"
            ##         % endif
            ##             style="padding: 0; text-align: center; max-width: 60px;"/>
            ## </td>
            ## <td align="center">
            ##     <input type="text" placeholder="${str(dfltAbsolute)}" size="6" maxlength="8"
            ##         class="sceneAbsolute form-control input-scene" data-for-absolute="${epResult["absolute_number"]}"
            ##         id="sceneAbsolute_${show.indexerid}${"_"+str(epResult["absolute_number"])}"
            ##         title="Change this value if scene absolute numbering differs from the indexer absolute numbering. Generally used for anime shows."
            ##         % if dfltAbsNumbering:
            ##             value=""
            ##         % else:
            ##             value="${str(scAbsolute)}"
            ##         % endif
            ##             style="padding: 0; text-align: center; max-width: 60px;"/>
            ## </td>
            <td class="col-name">
                <img v-if="episode.description" src="images/info32.png" width="16" height="16" class="plotInfo" alt="" id="plot_info_' + season.seasonNumber + '_' + episode.episodeNumber" />
                <img v-else src="images/info32.png" width="16" height="16" class="plotInfoNone" alt="" />
                {{episode.name}}
            </td>
            <td class="col-name">{{episode.location}}</td>
            <td v-if="episode.fileSize" class="col-ep">{{prettyFileSize(episode.fileSize)}}</td>
            ## <td class="col-airdate">
            ##     % if int(epResult['airdate']) != 1:
            ##         ## Lets do this exactly like ComingEpisodes and History
            ##         ## Avoid issues with dateutil's _isdst on Windows but still provide air dates
            ##         <% airDate = datetime.datetime.fromordinal(epResult['airdate']) %>
            ##         % if airDate.year >= 1970 or show.network:
            ##             <% airDate = sbdatetime.sbdatetime.convert_to_setting(network_timezones.parse_date_time(epResult['airdate'], show.airs, show.network)) %>
            ##         % endif
            ##         <time datetime="${airDate.isoformat('T')}" class="date">${sbdatetime.sbdatetime.sbfdatetime(airDate)}</time>
            ##     % else:
            ##         Never
            ##     % endif
            ## </td>
            ## <td>
            ##     % if app.DOWNLOAD_URL and epResult['location'] and Quality.splitCompositeStatus(int(epResult['status'])).status in [DOWNLOADED, ARCHIVED]:
            ##         <%
            ##             filename = epResult['location']
            ##             for rootDir in app.ROOT_DIRS.split('|'):
            ##                 if rootDir.startswith('/'):
            ##                     filename = filename.replace(rootDir, "")
            ##             filename = app.DOWNLOAD_URL + urllib.quote(filename.encode('utf8'))
            ##         %>
            ##         <center><a href="${filename}">Download</a></center>
            ##     % endif
            ## </td>
            <td v-for="flag in episode.subtitles" class="col-subtitles" align="center">
                ## @TODO: ???
                ## alt="${subtitles.name_from_code(flag)}"
                <img v-bind:src="'images/subtitles/flags/' + flag + '.png'" width="16" height="11" onError="this.onerror=null;this.src='images/flags/unknown.png';" />
            </td>
            ##     <% curStatus, curQuality = Quality.splitCompositeStatus(int(epResult["status"])) %>
            ##     % if curQuality != Quality.NONE:
            ##         <td class="col-status">${statusStrings[curStatus]} ${renderQualityPill(curQuality)}</td>
            ##     % else:
            ##         <td class="col-status">${statusStrings[curStatus]}</td>
            ##     % endif
            ## <td class="col-search">
            ##     % if int(epResult["season"]) != 0:
            ##         % if (int(epResult["status"]) in Quality.SNATCHED + Quality.SNATCHED_PROPER + Quality.SNATCHED_BEST + Quality.DOWNLOADED ) and app.USE_FAILED_DOWNLOADS:
            ##             <a class="epRetry" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/retryEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img data-ep-search src="images/search16.png" height="16" alt="retry" title="Retry Download" /></a>
            ##         % else:
            ##             <a class="epSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/searchEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img data-ep-search src="images/search16.png" width="16" height="16" alt="search" title="Forced Search" /></a>
            ##         % endif
            ##         <a class="epManualSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}&amp;manual_search_type=episode"><img data-ep-manual-search src="images/manualsearch.png" width="16" height="16" alt="search" title="Manual Search" /></a>
            ##     % else:
            ##         <a class="epManualSearch" id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}" href="home/snatchSelection?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}&amp;manual_search_type=episode"><img data-ep-manual-search src="images/manualsearch.png" width="16" height="16" alt="search" title="Manual Search" /></a>
            ##     % endif
            ##     % if int(epResult["status"]) not in Quality.SNATCHED + Quality.SNATCHED_PROPER and app.USE_SUBTITLES and show.subtitles and epResult["location"] and subtitles.needs_subtitles(epResult['subtitles']):
            ##         <a class="epSubtitlesSearch" href="home/searchEpisodeSubtitles?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img src="images/closed_captioning.png" height="16" alt="search subtitles" title="Search Subtitles" /></a>
            ##     % endif
            ## </td>
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
</div>
<!--End - Bootstrap Modal-->
</%block>
