// Injected into Steam's SharedJSContext by hide-playtime.mjs. Zeroes the
// signed-in user's playtime in the client UI's copy of the app data; Steam
// hides its playtime widgets when the value is 0. Display-only: tracking and
// the playtime stored on Steam's servers are untouched.
(() => {
  if (window.__hidePlaytime) return "already";
  if (typeof appStore === "undefined" || !appStore.m_mapApps?.size) return "not ready";
  if (typeof appDetailsStore === "undefined") return "not ready";
  if (typeof LocalizationManager === "undefined" || !LocalizationManager.m_mapTokens.size) return "not ready";

  const scrubOverview = (app) => {
    app.minutes_playtime_forever = 0;
    app.minutes_playtime_last_two_weeks = 0;
  };
  const scrubDetails = (details) => {
    if (details && typeof details === "object") {
      if ("nPlaytimeForever" in details) details.nPlaytimeForever = 0;
      if ("nPlaytimeLastTwoWeeks" in details) details.nPlaytimeLastTwoWeeks = 0;
    }
    return details;
  };

  // Library overviews: every create and update goes through InitFromProto.
  const Overview = appStore.m_mapApps.values().next().value.constructor;
  const initFromProto = Overview.prototype.InitFromProto;
  Overview.prototype.InitFromProto = function (...args) {
    const result = initFromProto.apply(this, args);
    scrubOverview(this);
    return result;
  };
  appStore.m_mapApps.forEach(scrubOverview);

  // Hover cards and shelves format 0 as "0 min" and only hide the block when
  // the text is empty, so blank the playtime strings (again on any reload).
  const playtimeToken =
    /^(AppBox_(TotalPlayTime|RecentPlayTime|PlayTimeHeader|NoPlayTimeYet)|BasicGameCarousel_TotalPlayTime|AppOverlay_GameOverview_(TotalPlaytime|LastTwoWeeksPlaytime|Playtime))/;
  const blankTokens = () => {
    for (const map of [LocalizationManager.m_mapTokens, LocalizationManager.m_mapFallbackTokens]) {
      for (const key of map.keys()) if (playtimeToken.test(key)) map.set(key, "");
    }
  };
  for (const method of ["InitFromObjects", "InitDirect", "AddTokens"]) {
    const original = LocalizationManager[method];
    LocalizationManager[method] = function (...args) {
      const result = original.apply(this, args);
      blankTokens();
      return result;
    };
  }
  blankTokens();

  // Game page play bar: details arrive through RegisterForAppDetails callbacks.
  const apps = SteamClient.Apps;
  const registerForAppDetails = apps.RegisterForAppDetails;
  apps.RegisterForAppDetails = function (appid, callback, ...rest) {
    const wrapped = (details, ...cbRest) => callback(scrubDetails(details), ...cbRest);
    return registerForAppDetails.call(this, appid, wrapped, ...rest);
  };
  // Re-register details subscriptions made before this script ran.
  appDetailsStore.m_mapAppData.forEach((data, appid) => {
    scrubDetails(data.details);
    if (data.cRegistered > 0 && data.hAppDetails) {
      data.hAppDetails.unregister();
      data.hAppDetails = apps.RegisterForAppDetails(appid, appDetailsStore.AppDetailsChanged);
    }
  });

  window.__hidePlaytime = true;
  return "injected";
})();
